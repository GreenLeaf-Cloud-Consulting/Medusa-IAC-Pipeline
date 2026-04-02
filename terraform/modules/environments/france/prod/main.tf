# France Production Environment
# Architecture EKS - Online Boutique (11 microservices)

terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = "eu-west-3" # Paris
}

locals {
  environment = "prod"
  region_name = "france"
}

# ==================== VPC ====================
module "vpc" {
  source = "../../../vpc"

  environment  = local.environment
  region_name  = local.region_name
  vpc_cidr     = "10.0.0.0/16"

  availability_zones = [
    "eu-west-3a",
    "eu-west-3b",
    "eu-west-3c"
  ]

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  private_subnet_cidrs = [
    "10.0.11.0/24",
    "10.0.12.0/24",
    "10.0.13.0/24"
  ]
}

# ==================== EKS ====================
module "eks" {
  source = "../../../eks"

  environment        = local.environment
  region_name        = local.region_name
  aws_region         = "eu-west-3"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  node_instance_type = "t3.large"
  node_min_size      = 1
  node_desired_size  = 2
  node_max_size      = 6
}
