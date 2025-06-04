variable "env" {
  type        = string
  description = "value of the environment, e.g. dev, staging, prod"
}

variable "tags" {
  type        = map(string)
  description = "value of the tags to be applied to the resources"
}

variable "ip_whitelist" {
  type        = list(string)
  description = "value of the IP addresses to whitelist for SSH access and to be used in security groups"
}


# variable "eks_admin_arn" {
#   type = list(string)
#   description = "ARN of the IAM role that will be used for EKS admin access"
# }
