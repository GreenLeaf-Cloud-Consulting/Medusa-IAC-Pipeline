variable "personal_prefix" {
  description = "Personal prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "region_short" {
  description = "Short region name (e.g., fr, de)"
  type        = string
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "create_iam_role" {
  description = "Create IAM role and instance profile for EC2 access"
  type        = bool
  default     = true
}
