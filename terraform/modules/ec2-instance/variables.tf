variable "allowed_ports" {
  description = "List of allowed ports for the security group"
  type    = list(number)
  default     = [22, 80, 443]
}

variable "region" {
  description = "The AWS region where resources will be created"
  type        = string
}

variable "ami" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
}

variable "environment" {
  description = "The deployment environment"
  type        = string
}

variable "instance_name" {
  description = "The name of the instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the instance will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the instance (required for ALB integration)"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB Target Group to register this instance with"
  type        = string
  default     = ""
}

variable "alb_security_group_id" {
  description = "Security Group ID of the ALB (to allow traffic from ALB)"
  type        = string
  default     = ""
}

variable "database_security_group_id" {
  description = "Security Group ID of the database instances (to allow DB access)"
  type        = string
  default     = ""
}

variable "enable_public_ip" {
  description = "Allocate a public IP for the instance (disable if behind ALB)"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = null
}