variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region_name" {
  description = "Region name for resource naming (france, germany)"
  type        = string
}

variable "aws_region" {
  description = "AWS region code (e.g. eu-west-3)"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}

variable "eks_cluster_name" {
  description = "Nom du cluster EKS à surveiller"
  type        = string
}

variable "cpu_threshold" {
  description = "CPU utilization percentage threshold to trigger alarm"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "Memory utilization percentage threshold to trigger alarm"
  type        = number
  default     = 80
}
