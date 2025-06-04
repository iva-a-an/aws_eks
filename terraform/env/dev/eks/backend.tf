terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "tf-eks-infinite-hen" ## TODO : See "init" project reference. terraform state list and then show
    key    = "terraform/dev.project_demo.tfstate"
    region = "us-east-1"
  }

}

provider "random" {}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1" ## TODO : Change the region to be Global variable
}


