variable "personal_prefix" {
  description = "Personal prefix for resource naming"
  type        = string
  default     = "jugurta-dev"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "discord_webhook" {
  description = "Discord webhook URL for CloudWatch alarm notifications"
  type        = string
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin"
}
