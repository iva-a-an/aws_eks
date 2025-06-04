variable "env" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {
    env       = "dev"
    owner     = "devops"
    terraform = "true"
    project   = "demo"
  }
}
