variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "ip_whitelist" {
  type = list(string)
}

variable "admin_ssh_public_key" {
  type = string  
}


# variable "eks_admin_arn" {
#   type = list(string)
#   description = "ARN of the IAM role that will be used for EKS admin access"
# }