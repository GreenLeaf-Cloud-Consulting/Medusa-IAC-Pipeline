output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_security_group_id" {
  description = "Security Group ID of the ALB"
  value       = aws_security_group.alb.id
}

output "security_group_id" {
  description = "Security Group ID of the ALB (alias)"
  value       = aws_security_group.alb.id
}

output "target_group_backend_arn" {
  description = "ARN of the backend target group"
  value       = aws_lb_target_group.backend.arn
}

output "target_group_storefront_arn" {
  description = "ARN of the storefront target group"
  value       = var.enable_storefront ? aws_lb_target_group.storefront[0].arn : null
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = var.enable_https ? aws_lb_listener.https[0].arn : null
}
