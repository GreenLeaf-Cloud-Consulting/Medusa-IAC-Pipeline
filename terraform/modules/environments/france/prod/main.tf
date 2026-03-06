# France Production Environment
# Architecture complète avec ALB, 2 App instances, 1 DB Primary, 1 DB Replica

terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = "eu-west-2" # London
}

locals {
  environment = "prod"
  region_name = "france"
  ami_debian_x86  = "ami-0f0f149abf454a472" # (optionnel) Debian 12 x86_64 eu-west-2
  ami_debian_arm  = "ami-0acc7dd449f810b83" # (optionnel) Debian 12 ARM64 eu-west-2
}

# ✅ AMI Debian 12 ARM64 la plus récente (dans eu-west-2)
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

# AMI Debian 12 x86_64 la plus récente (pour monitoring t3.micro)
data "aws_ami" "debian12_x86" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
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
  vpc_cidr     = "10.0.0.0/16"

  availability_zones = [
    "eu-west-2a",
    "eu-west-2b"
  ]

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

# ==================== ALB ====================
module "alb" {
  source = "../../../alb"

  environment             = local.environment
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
# Primary Database (France)
module "database_primary" {
  source = "../../../database"

  environment       = local.environment
  region_name       = local.region_name
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  availability_zone = module.vpc.availability_zones[0]
  ami               = data.aws_ami.debian12_arm64.id

  is_primary        = true
  instance_type     = "t4g.micro"
  replica_count     = 0

  ebs_volume_size   = 30
  ebs_volume_type   = "gp3"
  ebs_iops          = 3000
  ebs_throughput    = 125

  allocate_eip      = true

  app_security_group_ids = [
    module.app_instance_1.security_group_id,
    module.app_instance_2.security_group_id
  ]

  # Allow cross-region replication from Germany replica (using public IP)
  peer_database_cidr_blocks = ["0.0.0.0/0"]  # À restreindre avec l'IP publique de Germany

  ssh_cidr_blocks = ["0.0.0.0/0"]
}

# Replica Database (France)
module "database_replica_france" {
  source = "../../../database"

  environment       = local.environment
  region_name       = "${local.region_name}-replica"
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[1]
  availability_zone = module.vpc.availability_zones[1]
  ami               = data.aws_ami.debian12_arm64.id

  is_primary            = false
  replica_instance_type = "t4g.micro"
  replica_count         = 1

  replica_ebs_volume_size = 30
  ebs_volume_type         = "gp3"
  ebs_iops                = 3000
  ebs_throughput          = 125

  primary_ip_address = module.database_primary.primary_instance_private_ip

  app_security_group_ids = [
    module.app_instance_1.security_group_id,
    module.app_instance_2.security_group_id
  ]

  # Allow cross-region replication from Germany replica
  peer_database_cidr_blocks = []

  ssh_cidr_blocks = ["0.0.0.0/0"]
}

# ==================== APP INSTANCES ====================
# App Instance 1
module "app_instance_1" {
  source = "../../../ec2-instance"

  environment   = local.environment
  region        = "eu-west-2"
  instance_name = "app-1"
  ami           = data.aws_ami.debian12_x86.id
  instance_type = "t3.micro"

  vpc_id                      = module.vpc.vpc_id
  subnet_id                   = module.vpc.public_subnet_ids[0]
  enable_public_ip            = true

  alb_target_group_arn        = module.alb.target_group_backend_arn
  alb_security_group_id       = module.alb.security_group_id
  database_security_group_id  = module.database_primary.security_group_id

  ssh_user  = "admin"
  user_data = file("${path.module}/../../../monitoring/scripts/install_node_exporter.sh")
}

# App Instance 2
module "app_instance_2" {
  source = "../../../ec2-instance"

  environment   = local.environment
  region        = "eu-west-2"
  instance_name = "app-2"
  ami           = data.aws_ami.debian12_x86.id
  instance_type = "t3.micro"

  vpc_id                      = module.vpc.vpc_id
  subnet_id                   = module.vpc.public_subnet_ids[1]
  enable_public_ip            = true

  alb_target_group_arn        = module.alb.target_group_backend_arn
  alb_security_group_id       = module.alb.security_group_id
  database_security_group_id  = module.database_primary.security_group_id

  ssh_user  = "admin"
  user_data = file("${path.module}/../../../monitoring/scripts/install_node_exporter.sh")
}

# ==================== EKS ====================
module "eks" {
  source = "../../../eks"

  environment  = local.environment
  region_name  = local.region_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.public_subnet_ids
}

# ==================== CLOUDWATCH ====================
module "cloudwatch" {
  source = "../../../cloudwatch"

  environment  = local.environment
  region_name  = local.region_name
  aws_region   = "eu-west-2"
  alert_email  = "equipe@greenleaf.com"

  instance_ids = [
    module.app_instance_1.instance_id,
    module.app_instance_2.instance_id,
    module.database_primary.primary_instance_id,
  ]

  instance_names = ["app-1", "app-2", "db-primary"]
  cpu_threshold  = 70

  # Discord notifications
  enable_discord_notifications = true
  discord_webhook              = var.discord_webhook

  # Budget FinOps
  enable_budget      = true
  budget_limit       = "100"
  budget_alert_email = "vitomirlaces+greenleaf@gmail.com"
}

# ==================== MONITORING (Prometheus + Grafana) ====================
module "monitoring" {
  source = "../../../monitoring"

  environment  = local.environment
  region_name  = local.region_name
  aws_region   = "eu-west-2"
  vpc_id       = module.vpc.vpc_id
  subnet_id    = module.vpc.public_subnet_ids[0]
  ami           = data.aws_ami.debian12_x86.id
  instance_type = "t3.micro"

  grafana_admin_password = var.grafana_admin_password

  monitored_instances = [
    { name = "app-1",      private_ip = module.app_instance_1.instance_private_ip },
    { name = "app-2",      private_ip = module.app_instance_2.instance_private_ip },
    { name = "db-primary", private_ip = module.database_primary.primary_instance_private_ip },
  ]

  app_security_group_ids = [
    module.app_instance_1.security_group_id,
    module.app_instance_2.security_group_id,
    module.database_primary.security_group_id,
  ]
}
