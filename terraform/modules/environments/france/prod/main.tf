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
  node_desired_size  = 3
  node_max_size      = 10

  # Spot Instances : node group séparé pour les pics (~70% moins cher)
  enable_spot_nodes  = true
  spot_node_max_size = 4
}

# ==================== BUDGET ALERTS ====================
module "budget" {
  source = "../../../budget"

  team_name          = "rayane"
  monthly_budget_usd = 600
  alert_email        = "jugurta1999@gmail.com"
}

# ==================== CLOUDWATCH CONTAINER INSIGHTS ====================
module "cloudwatch" {
  source = "../../../cloudwatch"

  environment      = local.environment
  region_name      = local.region_name
  aws_region       = "eu-west-3"
  alert_email      = "jugurta1999@gmail.com"
  eks_cluster_name = module.eks.cluster_name
  cpu_threshold    = 80
  memory_threshold = 80
}

# ==================== WAF ====================
module "waf" {
  source = "../../../waf"

  environment = local.environment
  region_name = local.region_name
  # elb_arn laissé vide : K8s crée un Classic ELB, incompatible avec WAFv2
  # Pour associer : récupérer l'ARN de l'ALB si on passe à service type: LoadBalancer + annotations ALB
  elb_arn = ""
}
