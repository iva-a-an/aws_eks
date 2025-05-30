## TODO: VPC should be part of another "backbone" module
resource "aws_vpc" "vpc_demo" {
  cidr_block = "172.16.0.0/16"
  tags = var.tags
}

resource "aws_subnet" "subnet_demo" {
  vpc_id     = aws_vpc.vpc_demo.id
  cidr_block = "172.16.10.0/24"  
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = merge(var.tags, {"Name": "subnet_demo"})
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_demo.id
  tags = merge(var.tags, {"Name": "demo"})
}


resource "aws_route_table" "demo" {
  vpc_id = aws_vpc.vpc_demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  # }

  tags = {
    Name = "example"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.subnet_demo.id
  route_table_id = aws_route_table.demo.id
}

## TODO: Data section could not be nessasary. Check if value can be hardcoded or sent as variable
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
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


## Allow VM_A to read secret demo_user
data "aws_iam_policy_document" "secretsmanager" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:us-east-1:754430234629:secret:demo_user-*"]
  }
}

resource "aws_iam_role" "secretsmanager" {
  name               = "secretsmanager"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "secretsmanager" {
  name   = "secretsmanager"
  role   = aws_iam_role.secretsmanager.id
  policy = data.aws_iam_policy_document.secretsmanager.json
}

resource "aws_iam_instance_profile" "secretsmanager_profile" {
  name = "secretsmanager_profile"
  role = aws_iam_role.secretsmanager.name
}


## VM_A
resource "aws_instance" "vm_a" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.allow_ssh.id ]
  subnet_id = aws_subnet.subnet_demo.id
  iam_instance_profile = aws_iam_instance_profile.secretsmanager_profile.name


  user_data = <<-EOF
#!/bin/bash
# serial = 2024031703
authorized_keys_file=/home/ubuntu/.ssh/authorized_keys
touch $authorized_keys_file
echo "${var.admin_ssh_public_key}" >> $authorized_keys_file
chmod 600 $authorized_keys_file
chown ubuntu:ubuntu $authorized_keys_file
  EOF

  tags = merge(var.tags, {"Name": "demo_vm_a"})

}

## VM_A
resource "aws_instance" "vm_b" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.allow_ssh.id ]
  subnet_id = aws_subnet.subnet_demo.id


  user_data = <<-EOF
#!/bin/bash
# serial = 2024031703
authorized_keys_file=/home/ubuntu/.ssh/authorized_keys
touch $authorized_keys_file
echo "${var.admin_ssh_public_key}" >> $authorized_keys_file
chmod 600 $authorized_keys_file
chown ubuntu:ubuntu $authorized_keys_file
  EOF

  tags = merge(var.tags, {"Name": "demo_vm_b"})
}


