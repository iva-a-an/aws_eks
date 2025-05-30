output "vm_a_ip" {
  value = aws_instance.vm_a.public_ip
}

output "vm_b_ip" {
  value = aws_instance.vm_b.public_ip
}

