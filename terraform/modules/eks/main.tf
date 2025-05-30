resource "aws_iam_role" "eks-cluster" {
  name = "${var.env}-eks-cluster-role"
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
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster.name
}


resource "aws_eks_access_entry" "admin_user_access" {
  cluster_name  = aws_eks_cluster.aks.name
  principal_arn = "arn:aws:iam::754430234629:user/ross"
  # The 'type' can be "STANDARD" (default) or "FARGATE_PROFILE" or "EC2_LINUX" etc.
  # For a user, "STANDARD" is appropriate.
  type          = "STANDARD"

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "EKSAdminAccess"
  }
}


resource "aws_eks_access_policy_association" "example" {
  cluster_name  = aws_eks_cluster.aks.name
  policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.admin_user_access.principal_arn

  access_scope {
    type       = "cluster"
  }
}


resource "aws_eks_cluster" "aks" {
  name = "${var.env}-aks-demo"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.eks-cluster.arn
  version  = "1.31"

  vpc_config {
    subnet_ids = [
        var.private_subnet_a_id,
        var.private_subnet_b_id
    ]
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]
}
