# hub and spoke vpc module
# This module creates a VPC with public and private subnets, an internet gateway, and a route table.
# TODO: Add loops for k8s subeets and routeing table


# VPC
resource "aws_vpc" "vpc_demo" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { "Name" : "${var.env}-vpc_demo" })
}

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.vpc_demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, { "Name" : "public_route_table" })
}

resource "aws_route_table_association" "private_subnet_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "private_subnet_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.public.id
}

# PUBLIC SUBNETS
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc_demo.id
  cidr_block              = var.public_subnets_cidr
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { "Name" : "${var.env}-subnet_demo" })
}


# PRIVATE SUBNETS
resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.vpc_demo.id
  cidr_block              = var.private_subnets_a_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a" # Specify the availability zone if needed
  tags = merge(var.tags, {
    "Name" = "${var.env}-private_subnet_a",
    "kubernetes.io/role/elb" : "1"
  })
  # add dns resolution and hostnames

}


resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = aws_vpc.vpc_demo.id
  cidr_block              = var.private_subnets_b_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b" # Specify the availability zone if needed
  tags = merge(var.tags, {
    "Name"                   = "${var.env}-private_subnet_b"
    "kubernetes.io/role/elb" = "1"
  })

}


# Internet Getway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_demo.id
  tags   = merge(var.tags, { "Name" : "${var.env}-internet-gateway" })
}


## SECURITY GROUP
resource "aws_security_group" "allow_ssh" {
  name        = "ssh_in"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.vpc_demo.id
  tags        = merge(var.tags, { "Name" : "ssh_in" })

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
