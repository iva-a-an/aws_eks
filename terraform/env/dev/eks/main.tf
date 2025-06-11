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
  vpc_id              = module.network.vpc_id
  private_subnet_a_id = module.network.private_subnet_a_id
  private_subnet_b_id = module.network.private_subnet_b_id
  env                 = var.env
  tags                = var.tags
}

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.env}-ec2-elb-instance"

  instance_type          = "t3.micro"
  vpc_security_group_ids = [module.network.default_security_group_id]
  subnet_id              = module.network.private_subnet_a_id

  tags = var.tags
}
