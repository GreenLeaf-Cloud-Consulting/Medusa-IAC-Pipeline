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
