output "private_subnet_a_id" {
  value       = aws_subnet.private_subnet_a.id
  description = "The ID of the private subnet A"
}

output "private_subnet_b_id" {
  value       = aws_subnet.private_subnet_b.id
  description = "The ID of the private subnet B"
}

output "vpc_id" {
  value       = aws_vpc.vpc_demo.id
  description = "The ID of the VPC"
}

output "default_security_group_id" {
  value       = aws_vpc.vpc_demo.default_security_group_id
  description = "The ID of the default security group for the VPC"
}
