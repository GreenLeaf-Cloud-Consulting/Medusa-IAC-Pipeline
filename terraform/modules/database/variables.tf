variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region_name" {
  description = "Region name (france, germany)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where database will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for database instance"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the database"
  type        = string
}

variable "ami" {
  description = "AMI ID for the database instance (Debian/Ubuntu recommended)"
  type        = string
}

variable "instance_type" {
  description = "Instance type for PRIMARY database"
  type        = string
  default     = "t2.medium"
}

variable "replica_instance_type" {
  description = "Instance type for REPLICA databases"
  type        = string
  default     = "t2.small"
}

variable "is_primary" {
  description = "Whether this is a primary database instance"
  type        = bool
  default     = false
}

variable "replica_count" {
  description = "Number of replica instances to create"
  type        = number
  default     = 0
}

variable "ebs_volume_size" {
  description = "Size of EBS volume for PRIMARY database (GB)"
  type        = number
  default     = 100
}

variable "replica_ebs_volume_size" {
  description = "Size of EBS volume for REPLICA databases (GB)"
  type        = number
  default     = 100
}

variable "ebs_volume_type" {
  description = "Type of EBS volume (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "ebs_iops" {
  description = "IOPS for EBS volume (only for gp3, io1, io2)"
  type        = number
  default     = 3000
}

variable "ebs_throughput" {
  description = "Throughput for EBS volume in MB/s (only for gp3)"
  type        = number
  default     = 125
}

variable "app_security_group_ids" {
  description = "List of security group IDs for app servers that need DB access"
  type        = list(string)
  default     = []
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH into database instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # À restreindre en production !
}

variable "allocate_eip" {
  description = "Allocate Elastic IP for PRIMARY instance"
  type        = bool
  default     = true
}

variable "primary_ip_address" {
  description = "IP address of the PRIMARY database (for replicas to connect)"
  type        = string
  default     = ""
}
