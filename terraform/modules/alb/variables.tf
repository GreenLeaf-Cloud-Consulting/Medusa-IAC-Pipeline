variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region_name" {
  description = "Region name (france, germany)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "backend_port" {
  description = "Port for backend application"
  type        = number
  default     = 9000
}

variable "storefront_port" {
  description = "Port for storefront application"
  type        = number
  default     = 8000
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "enable_storefront" {
  description = "Enable storefront target group"
  type        = bool
  default     = false
}

variable "enable_https" {
  description = "Enable HTTPS listener"
  type        = bool
  default     = false
}

variable "enable_https_redirect" {
  description = "Redirect HTTP to HTTPS"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for HTTPS"
  type        = string
  default     = ""
}
