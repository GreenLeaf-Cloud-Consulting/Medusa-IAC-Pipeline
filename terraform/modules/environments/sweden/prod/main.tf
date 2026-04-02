# Sweden Production Environment (Stockholm)
# Architecture complète avec ALB, 2 App instances, 1 DB Replica, EKS

terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = "eu-north-1" # Stockholm
}

locals {
  environment = "prod"
  region_name = "sweden"
}

# ✅ AMI Debian 12 ARM64 la plus récente (dans eu-north-1)
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

  environment  = local.environment
  region_name  = local.region_name
  vpc_cidr     = "10.2.0.0/16"

  availability_zones = [
    "eu-north-1a",
    "eu-north-1b"
  ]

  public_subnet_cidrs = [
    "10.2.1.0/24",
    "10.2.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.2.11.0/24",
    "10.2.12.0/24"
  ]
}

# ==================== ALB ====================
module "alb" {
  source = "../../../alb"

  environment            = local.environment
  region_name            = local.region_name
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids

  backend_port    = 9000
  storefront_port = 8000

  enable_deletion_protection = false
  enable_storefront          = false
  enable_https               = false
  enable_https_redirect      = false
}

# ==================== DATABASE ====================
# Replica Database (Sweden) - Connects to France Primary
module "database_replica_sweden" {
  source = "../../../database"

  environment       = local.environment
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

  app_security_group_ids = [
    module.app_instance_1.security_group_id,
    module.app_instance_2.security_group_id
  ]

  peer_database_cidr_blocks = []
  ssh_cidr_blocks           = ["0.0.0.0/0"]
}

# ==================== APP INSTANCES ====================
# App Instance 1
module "app_instance_1" {
  source = "../../../ec2-instance"

  environment   = local.environment
  region        = "eu-north-1"
  instance_name = "app-1"
  ami           = data.aws_ami.debian12_arm64.id
  instance_type = "t4g.small"

  vpc_id                     = module.vpc.vpc_id
  subnet_id                  = module.vpc.public_subnet_ids[0]
  enable_public_ip           = true

  alb_target_group_arn       = module.alb.target_group_backend_arn
  alb_security_group_id      = module.alb.security_group_id
  database_security_group_id = module.database_replica_sweden.security_group_id

  ssh_user = "admin"
}

# App Instance 2
module "app_instance_2" {
  source = "../../../ec2-instance"

  environment   = local.environment
  region        = "eu-north-1"
  instance_name = "app-2"
  ami           = data.aws_ami.debian12_arm64.id
  instance_type = "t4g.small"

  vpc_id                     = module.vpc.vpc_id
  subnet_id                  = module.vpc.public_subnet_ids[1]
  enable_public_ip           = true

  alb_target_group_arn       = module.alb.target_group_backend_arn
  alb_security_group_id      = module.alb.security_group_id
  database_security_group_id = module.database_replica_sweden.security_group_id

  ssh_user = "admin"
}

# ==================== EKS ====================
module "eks" {
  source = "../../../eks"

  environment = local.environment
  region_name = local.region_name
  aws_region  = "eu-north-1"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnet_ids
}
