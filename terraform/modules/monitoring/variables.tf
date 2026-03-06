variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region_name" {
  description = "Region name for resource naming (france, germany, sweden)"
  type        = string
}

variable "aws_region" {
  description = "AWS region code (e.g. eu-west-2)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the monitoring instance will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the monitoring instance"
  type        = string
}

variable "ami" {
  description = "AMI ID for the monitoring instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the monitoring server"
  type        = string
  default     = "t4g.micro"
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "grafana_cidr_blocks" {
  description = "CIDR blocks allowed for Grafana access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "prometheus_cidr_blocks" {
  description = "CIDR blocks allowed for Prometheus access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "monitored_instances" {
  description = "List of instances to monitor with node_exporter (name and private_ip)"
  type = list(object({
    name       = string
    private_ip = string
  }))
}

variable "app_security_group_ids" {
  description = "Security group IDs of the app/db instances (to allow node_exporter scraping)"
  type        = list(string)
  default     = []
}
