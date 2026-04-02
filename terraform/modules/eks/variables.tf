variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region_name" {
  description = "Region name for resource naming (france, germany)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS cluster and node group"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region (ex: eu-west-2, eu-central-1, eu-north-1)"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1
}

variable "node_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

variable "enable_spot_nodes" {
  description = "Activer un node group Spot pour réduire les coûts (~70% moins cher)"
  type        = bool
  default     = false
}

variable "spot_node_max_size" {
  description = "Nombre max de nodes Spot (pour les pics de charge)"
  type        = number
  default     = 4
}
