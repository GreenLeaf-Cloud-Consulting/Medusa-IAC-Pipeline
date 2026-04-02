# ==========================================
# MAIN TERRAFORM CONFIGURATION
# Architecture EKS multi-région - Online Boutique
# ==========================================
#
# MODE TEST (France uniquement)
# Pour déployer les 3 régions, décommenter germany_prod, sweden_prod
# ==========================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ==================== FRANCE PRODUCTION ====================
module "france_prod" {
  source = "./modules/environments/france/prod"
}

# ==================== GERMANY PRODUCTION ====================
# Décommenter pour déployer Germany
# module "germany_prod" {
#   source = "./modules/environments/germany/prod"
# }

# ==================== SWEDEN PRODUCTION ====================
# Décommenter pour déployer Sweden
# module "sweden_prod" {
#   source = "./modules/environments/sweden/prod"
# }

# ==================== SHARED S3 BUCKET ====================
module "s3_global" {
  source = "./modules/s3"

  providers = {
    aws = aws.ireland
  }

  personal_prefix = var.personal_prefix
  environment     = "prod"
  region_short    = "global"

  enable_versioning    = true
  cors_allowed_origins = ["*"]

  create_iam_role = false
}

provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}

# ==========================================
# OUTPUTS
# ==========================================

output "france_eks_cluster_name" {
  description = "Nom du cluster EKS France"
  value       = module.france_prod.eks_cluster_name
}

output "france_eks_cluster_endpoint" {
  description = "Endpoint du cluster EKS France"
  value       = module.france_prod.eks_cluster_endpoint
}

output "france_eks_kubeconfig_command" {
  description = "Commande kubectl pour le cluster EKS France"
  value       = module.france_prod.eks_kubeconfig_command
}

output "s3_bucket_name" {
  description = "Nom du bucket S3 partagé"
  value       = module.s3_global.bucket_name
}

output "deployment_complete" {
  value = <<-EOT
    ==========================================
    DEPLOIEMENT TERRAFORM TERMINE !
    ==========================================

    FRANCE (eu-west-3) :
       EKS Cluster : ${module.france_prod.eks_cluster_name}
       Endpoint    : ${module.france_prod.eks_cluster_endpoint}

    PROCHAINES ETAPES :
       bash deploy.sh

    ACCES Online Boutique :
       kubectl get svc frontend-external -n boutique
    ==========================================
  EOT
}
