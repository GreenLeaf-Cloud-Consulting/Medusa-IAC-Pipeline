variable "discord_webhook" {
  description = "Discord webhook URL for alarm notifications"
  type        = string
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin"
}
