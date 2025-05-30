# hub and spoke vpc module
# This module creates a VPC with public and private subnets, an internet gateway, and a route table.

# VPC
resource "aws_vpc" "vpc_demo" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = var.tags
}

# PUBLIC SUBNETS
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc_demo.id
  cidr_block = var.public_subnets_cidr
  map_public_ip_on_launch = true
  tags = merge(var.tags, {"Name": "subnet_demo"})
}


# PRIVATE SUBNETS
resource "aws_subnet" "private_subnet_a" {
  vpc_id = aws_vpc.vpc_demo.id
  cidr_block = var.private_subnets_a_cidr
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a" # Specify the availability zone if needed
  tags = merge(var.tags, {"Name": "private_subnet_a"})
}


resource "aws_subnet" "private_subnet_b" {
  vpc_id = aws_vpc.vpc_demo.id
  cidr_block = var.private_subnets_b_cidr
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b" # Specify the availability zone if needed
  tags = merge(var.tags, {"Name": "private_subnet_b"})
}


# Internet Getway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_demo.id
  tags = merge(var.tags, {"Name": "demo"})
}



## SECURITY GROUP
resource "aws_security_group" "allow_ssh" {
  name        = "ssh_in"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.vpc_demo.id
  tags        = merge(var.tags, {"Name": "ssh_in"})

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ip_whitelist
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}