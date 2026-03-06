variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region_name" {
  description = "Region name for resource naming (france, germany)"
  type        = string
}

variable "aws_region" {
  description = "AWS region code (e.g. eu-west-2)"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}

variable "instance_ids" {
  description = "List of EC2 instance IDs to monitor (must have at least 3: app1, app2, db)"
  type        = list(string)
}

variable "instance_names" {
  description = "List of human-readable names for monitored instances (same order as instance_ids)"
  type        = list(string)
}

variable "cpu_threshold" {
  description = "CPU utilization percentage threshold to trigger alarm"
  type        = number
  default     = 70
}

# --- Discord Lambda ---

variable "discord_webhook" {
  description = "Discord webhook URL for alarm notifications"
  type        = string
  default     = ""
}

variable "enable_discord_notifications" {
  description = "Enable Discord notifications via Lambda"
  type        = bool
  default     = false
}

# --- Budget ---

variable "enable_budget" {
  description = "Enable AWS Budget alerts"
  type        = bool
  default     = false
}

variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "100"
}

variable "budget_alert_email" {
  description = "Email address for budget alert notifications"
  type        = string
  default     = ""
}

# --- Network Alarms ---

variable "network_in_threshold" {
  description = "Network In threshold in bytes (default 5MB)"
  type        = number
  default     = 5242880
}

variable "network_out_threshold" {
  description = "Network Out threshold in bytes (default 5MB)"
  type        = number
  default     = 5242880
}

# --- EBS Alarms ---

variable "ebs_write_ops_threshold" {
  description = "EBS Write Ops threshold (IOPS)"
  type        = number
  default     = 3000
}

variable "ebs_write_bytes_threshold" {
  description = "EBS Write Bytes threshold in bytes (default 100MB)"
  type        = number
  default     = 104857600
}
