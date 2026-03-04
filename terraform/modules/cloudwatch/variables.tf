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
