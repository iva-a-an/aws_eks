terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "random" {}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1" ## TODO : Change the region to be Global variable
}
