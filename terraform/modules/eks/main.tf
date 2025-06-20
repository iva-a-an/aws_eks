# EKS cluster moduele



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
  instance_types  = var.env == "prod" ? ["t3.medium", "t3.large"] : ["t3.medium"]
  capacity_type   = "SPOT"
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


# Build the OIDC trust relationship for the EKS cluster
# This is required for the EBS CSI driver to work with EKS.
# The OIDC provider is used to authenticate Kubernetes service accounts with AWS IAM roles.
# This is necessary for the EBS CSI driver to function properly.
# The OIDC provider is automatically created by EKS when the cluster is created.
# The OIDC provider URL is in the format: https://oidc.eks.<region>.amazonaws.com/id/<eks-cluster-id>
# The thumbprint is the SHA1 fingerprint of the certificate used by the OIDC provider.
# The thumbprint is used to verify the authenticity of the OIDC provider.
# The OIDC provider is used to authenticate Kubernetes service accounts with AWS IAM roles.
# The OIDC provider is automatically created by EKS when the cluster is created.
# The OIDC provider URL is in the format: https://oidc.eks.<region>.amazonaws.com/id/<eks-cluster-id>
# The thumbprint is the SHA1 fingerprint of the certificate used by the OIDC provider.
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}


data "aws_iam_policy_document" "csi" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_ebs_csi_driver" {
  assume_role_policy = data.aws_iam_policy_document.csi.json
  name               = "eks-ebs-csi-driver"
}

resource "aws_iam_role_policy_attachment" "amazon_ebs_csi_driver" {
  role       = aws_iam_role.eks_ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# CSI Driver addon
resource "aws_eks_addon" "csi_driver" {
  cluster_name             = aws_eks_cluster.eks.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.eks_ebs_csi_driver.arn
}


# Ingress Controller IAM Role
data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy.json
  name               = "aws-load-balancer-controller"
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  policy = file("${path.module}/policies/aws_elb_ingress_policy.json")
  name   = "AWSLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}
