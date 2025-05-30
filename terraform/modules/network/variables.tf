variable "env" {
  description = "prod or dev"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets_cidr" {
  description = "CIDR block for the public subnets"
  type        = string
}

variable "private_subnets_a_cidr" {
  description = "CIDR block for the private subnets"
  type        = string  
}

variable "private_subnets_b_cidr" {
  description = "CIDR block for the private subnets"
  type        = string  
}

variable "ip_whitelist" {
   description = "values to be used for whitelisting IPs"
   type = list(string)
}
