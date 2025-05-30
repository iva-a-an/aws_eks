variable "env" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {
    env = "dev"
    owner = "devops"
  }
}

variable "terraform_user_id" {
  type = string
  default = "AKIA27J4L2ACVE2SLIO4"
}