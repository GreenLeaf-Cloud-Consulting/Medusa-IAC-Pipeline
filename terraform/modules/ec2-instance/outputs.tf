output "instance_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.debian_instance.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the instance"
  value       = aws_instance.debian_instance.private_ip
}

output "instance_id" {
  description = "Instance ID"
  value       = aws_instance.debian_instance.id
}

output "ssh_private_key" {
  description = "SSH private key for the instance"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}

output "security_group_id" {
  description = "Security Group ID of the instance"
  value       = aws_security_group.instance_sg.id
}