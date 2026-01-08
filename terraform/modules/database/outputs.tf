output "primary_instance_id" {
  description = "ID of the PRIMARY database instance"
  value       = var.is_primary ? aws_instance.primary[0].id : null
}

output "primary_instance_private_ip" {
  description = "Private IP of the PRIMARY database instance"
  value       = var.is_primary ? aws_instance.primary[0].private_ip : null
}

output "primary_instance_public_ip" {
  description = "Public IP of the PRIMARY database instance"
  value       = var.is_primary ? aws_instance.primary[0].public_ip : null
}

output "primary_eip" {
  description = "Elastic IP of the PRIMARY database instance"
  value       = var.is_primary && var.allocate_eip ? aws_eip.primary[0].public_ip : null
}

output "replica_instance_ids" {
  description = "IDs of REPLICA database instances"
  value       = aws_instance.replica[*].id
}

output "replica_instance_private_ips" {
  description = "Private IPs of REPLICA database instances"
  value       = aws_instance.replica[*].private_ip
}

output "replica_instance_public_ips" {
  description = "Public IPs of REPLICA database instances"
  value       = aws_instance.replica[*].public_ip
}

output "security_group_id" {
  description = "Security Group ID for database instances"
  value       = aws_security_group.database.id
}

output "ssh_private_key_pem" {
  description = "SSH private key for database instances"
  value       = tls_private_key.db_ssh_key.private_key_pem
  sensitive   = true
}

output "ssh_key_name" {
  description = "SSH key pair name"
  value       = aws_key_pair.db_key.key_name
}

output "primary_ebs_volume_id" {
  description = "EBS Volume ID for PRIMARY database"
  value       = var.is_primary ? aws_ebs_volume.primary_data[0].id : null
}

output "replica_ebs_volume_ids" {
  description = "EBS Volume IDs for REPLICA databases"
  value       = aws_ebs_volume.replica_data[*].id
}

# Database connection strings (pour Ansible)
output "primary_connection_string" {
  description = "Connection string for PRIMARY database"
  value       = var.is_primary ? "postgres://medusa:password@${aws_instance.primary[0].private_ip}:5432/medusa" : null
  sensitive   = true
}

output "replica_connection_strings" {
  description = "Connection strings for REPLICA databases"
  value = [
    for instance in aws_instance.replica :
    "postgres://medusa:password@${instance.private_ip}:5432/medusa"
  ]
  sensitive = true
}
