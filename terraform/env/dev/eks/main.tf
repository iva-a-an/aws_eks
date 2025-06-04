module "network" {
  source                 = "../../../modules/network"
  vpc_cidr               = "10.0.0.0/16"
  public_subnets_cidr    = "10.0.1.0/24"
  private_subnets_a_cidr = "10.0.2.0/24"
  private_subnets_b_cidr = "10.0.3.0/24"
  env                    = var.env
  tags                   = var.tags
  ip_whitelist           = var.ip_whitelist
}


module "eks" {
  source              = "../../../modules/eks"
  private_subnet_a_id = module.network.private_subnet_a_id
  private_subnet_b_id = module.network.private_subnet_b_id
  env                 = var.env
  tags                = var.tags
}




# module "eks" {
#   source = "terraform-aws-modules/eks/aws"
#   version = "~> 20.31"

#   cluster_name = "${var.env}-eks-cluster"
#   cluster_version = "1.31"


#   # Optional
#   cluster_endpoint_public_access = true


#   # Optional: Adds the current caller identity as an administrator via cluster access entry
#   enable_cluster_creator_admin_permissions = true

#   eks_managed_node_groups = {
#     example = {
#       instance_types = ["t3.medium"]
#       min_size = 1
#       max_size = 2
#       desired_size = 1

#     }

#   }


#   vpc_id = module.network.vpc_id
#   subnet_ids = [
#     module.network.private_subnet_a_id,
#     module.network.private_subnet_b_id
#   ]


#   tags = {
#     Environment = "dev"
#     Terraform = "true"
#   }

# }
