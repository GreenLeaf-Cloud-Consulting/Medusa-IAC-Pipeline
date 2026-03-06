output "monitoring_public_ip" {
  description = "Public IP of the monitoring server"
  value       = aws_instance.monitoring.public_ip
}

output "monitoring_private_ip" {
  description = "Private IP of the monitoring server"
  value       = aws_instance.monitoring.private_ip
}

output "monitoring_instance_id" {
  description = "Instance ID of the monitoring server"
  value       = aws_instance.monitoring.id
}

output "grafana_url" {
  description = "Grafana web UI URL"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus web UI URL"
  value       = "http://${aws_instance.monitoring.public_ip}:9090"
}

output "ssh_monitoring" {
  description = "SSH command to connect to the monitoring server"
  value       = "ssh -i keys/${var.environment}-${var.aws_region}-monitoring-key.pem admin@${aws_instance.monitoring.public_ip}"
}

output "security_group_id" {
  description = "Security Group ID of the monitoring server"
  value       = aws_security_group.monitoring.id
}

output "ssh_private_key" {
  description = "SSH private key for the monitoring server"
  value       = tls_private_key.monitoring_key.private_key_pem
  sensitive   = true
}
