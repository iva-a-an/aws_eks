output "eks_cluster_name" {
  value = aws_eks_cluster.aks.name
}

output "eks_cluster_region" {
    value = split(":",aws_eks_cluster.aks.arn)[3]
}