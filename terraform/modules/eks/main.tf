resource "aws_iam_role" "eks_cluster" {
  name        = "${var.env}-eks_cluster"
  description = "EKS Cluster Role for ${var.env} environment"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.env}-eks_cluster-role"
    Environment = var.env
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# AmazonEKSVPCResourceController policy attaches the necessary permissions for EKS to manage VPC resources.
resource "aws_iam_role_policy_attachment" "eks_vpc_controller_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}


resource "aws_eks_cluster" "eks" {
  name = "${var.env}-eks-demo"

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false # Don't add current user as admin on cluster creation
  }

  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.31"

  vpc_config {
    subnet_ids = [
      var.private_subnet_a_id,
      var.private_subnet_b_id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  # enable logging for the cluster
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  kubernetes_network_config {
    ip_family = "ipv4"
  }


  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}



## ADD EKS ACCESS ENTRY
# TODO: Replace this with arn of group. 
resource "aws_eks_access_entry" "admin_user_access" {
  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = "arn:aws:iam::754430234629:user/ross"
  # The 'type' can be "STANDARD" (default) or "FARGATE_PROFILE" or "EC2_LINUX" etc.
  # For a user, "STANDARD" is appropriate.
  type = "STANDARD"

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "EKSAdminAccess"
  }
}


resource "aws_eks_access_policy_association" "eks" {
  cluster_name  = aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.admin_user_access.principal_arn

  access_scope {
    type = "cluster"
  }
}

## ADD NODE POOLS
resource "aws_iam_role" "eks_node_group" {
  name = "${var.env}-eks_node_group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


## TODO: Add loop? 
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}


resource "aws_eks_node_group" "spot" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.env}-eks-spot-ng"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  instance_types  = var.env == "prod" ? ["t3.medium", "t3.large"] : ["t3.small", "t3.medium"]
  subnet_ids = [
    var.private_subnet_a_id,
    var.private_subnet_b_id
  ]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ec2_container_registry_read_only,
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_controller_policy
  ]

  # add  kubernetes.io/cluster/my-cluster 
  tags = merge(var.tags, {
    "kubernetes.io/cluster/${aws_eks_cluster.eks.name}" = "owned"
    "Name"                                              = "${var.env}-eks-spot-ng"
  })
}
