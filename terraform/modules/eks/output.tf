output "eks_cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "eks_cluster_region" {
    value = split(":",aws_eks_cluster.eks.arn)[3]
}