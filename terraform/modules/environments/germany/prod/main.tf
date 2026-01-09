# Germany Production Environment
# Architecture complète avec ALB, 2 App instances, 1 DB Replica

terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = "eu-central-2" # Zurich
}

variable "personal_prefix" {
  description = "Personal prefix to avoid conflicts between team members"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

locals {
  region_name = "germany"
  ami_debian_x86  = "ami-06c431709bcd3b51d" # (optionnel) Debian 12 x86_64 eu-central-1
  ami_debian_arm  = "ami-0cadc0cd2c84f9c97" # (optionnel) Debian 12 ARM64 eu-central-1
}

# ✅ AMI Debian 12 ARM64 la plus récente (dans eu-central-1)
data "aws_ami" "debian12_arm64" {
  most_recent = true
  owners      = ["136693071363"] # Debian officiel sur AWS

  filter {
    name   = "name"
    values = ["debian-12-arm64-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==================== VPC ====================
module "vpc" {
  source = "../../../vpc"

  personal_prefix = var.personal_prefix
  environment     = var.environment
  region_name     = local.region_name
  vpc_cidr        = "10.1.0.0/16"

  availability_zones = [
  "eu-central-2a",
  "eu-central-2b"
  ]

  public_subnet_cidrs = [
    "10.1.1.0/24",
    "10.1.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.1.11.0/24",
    "10.1.12.0/24"
  ]
}

# ==================== ALB ====================
module "alb" {
  source = "../../../alb"

  personal_prefix         = var.personal_prefix
  environment             = var.environment
  region_name             = local.region_name
  vpc_id                  = module.vpc.vpc_id
  public_subnet_ids       = module.vpc.public_subnet_ids

  medusa_backend_port     = 9000
  medusa_storefront_port  = 8000

  enable_deletion_protection = false
  enable_storefront          = false
  enable_https               = false
  enable_https_redirect      = false
}

# ==================== DATABASE ====================
# Replica Database (Germany) - Connects to France Primary
module "database_replica_germany" {
  source = "../../../database"

  personal_prefix   = var.personal_prefix
  environment       = var.environment
  region_name       = local.region_name
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  availability_zone = module.vpc.availability_zones[0]
  ami               = data.aws_ami.debian12_arm64.id

  is_primary            = false
  replica_instance_type = "t4g.small"
  replica_count         = 1

  replica_ebs_volume_size = 30
  ebs_volume_type         = "gp3"
  ebs_iops                = 3000
  ebs_throughput          = 125

  # À remplir avec l'IP du Primary Database en France
  # primary_ip_address = "PRIMARY_DB_IP_FROM_FRANCE"

  app_security_group_ids = [
    module.app_instance_1.security_group_id,
    module.app_instance_2.security_group_id
  ]

  ssh_cidr_blocks = ["0.0.0.0/0"]
}

# ==================== APP INSTANCES ====================
# App Instance 1
module "app_instance_1" {
  source = "../../../ec2-instance"

  personal_prefix = var.personal_prefix
  environment     = var.environment
  region          = "eu-central-1"
  instance_name   = "app-1"
  ami             = data.aws_ami.debian12_arm64.id
  instance_type   = "t4g.small"

  vpc_id                      = module.vpc.vpc_id
  subnet_id                   = module.vpc.public_subnet_ids[0]
  enable_public_ip            = true

  alb_target_group_arn        = module.alb.target_group_backend_arn
  alb_security_group_id       = module.alb.security_group_id
  database_security_group_id  = module.database_replica_germany.security_group_id

  ssh_user      = "admin"
}

# App Instance 2
module "app_instance_2" {
  source = "../../../ec2-instance"

  personal_prefix = var.personal_prefix
  environment     = var.environment
  region          = "eu-central-1"
  instance_name   = "app-2"
  ami             = data.aws_ami.debian12_arm64.id
  instance_type   = "t4g.small"

  vpc_id                      = module.vpc.vpc_id
  subnet_id                   = module.vpc.public_subnet_ids[1]
  enable_public_ip            = true

  alb_target_group_arn        = module.alb.target_group_backend_arn
  alb_security_group_id       = module.alb.security_group_id
  database_security_group_id  = module.database_replica_germany.security_group_id

  ssh_user      = "admin"
}
