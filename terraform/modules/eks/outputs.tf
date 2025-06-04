output "eks_cluster_name" {
  value       = aws_eks_cluster.eks.name
  description = "The name of the EKS cluster"
}

output "eks_cluster_region" {
  value       = split(":", aws_eks_cluster.eks.arn)[3]
  description = "The region where the EKS cluster is deployed"
}
