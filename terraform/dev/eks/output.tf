# output "vm_a_ip" {
#   value = module.demo.vm_a_ip
# }

# output "vm_b_ip" {
#   value = module.demo.vm_b_ip
# }

# output "private_aws_subnet_a_id" {
#   value = module.network.private_a_subnet_id
# }

output "eks_cluster_name" {
  value = module.eks.eks_cluster_name
}

output "eks_cluster_region" {
  value = module.eks.eks_cluster_region
}