# ==========================================
# MAIN TERRAFORM CONFIGURATION - V2
# Architecture complète multi-région avec ALB + EKS
# ==========================================
#
# MODE TEST (France uniquement)
# Pour déployer les 3 régions, décommenter germany_prod, sweden_prod
# et leurs outputs/variables associés
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

  enable_versioning = true
  cors_allowed_origins = [
    "http://${module.france_prod.alb_url}",
    # "http://${module.germany_prod.alb_url}",   # décommenter avec germany_prod
    # "http://${module.sweden_prod.alb_url}",    # décommenter avec sweden_prod
    "http://localhost:9000",
    "http://localhost:8000",
    "http://localhost:7001"
  ]

  create_iam_role = true
}

provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}

# ==========================================
# OUTPUTS
# ==========================================

# France
output "france_alb_url" {
  description = "URL de l'ALB France"
  value       = module.france_prod.alb_url
}

output "france_app_instances" {
  description = "Instances App France"
  value       = module.france_prod.app_instances_info
}

output "france_database" {
  description = "Instances Database France"
  value       = module.france_prod.database_info
}

output "france_ecr_backend_url" {
  description = "URL ECR backend France"
  value       = module.france_prod.ecr_backend_url
}

output "france_ecr_storefront_url" {
  description = "URL ECR storefront France"
  value       = module.france_prod.ecr_storefront_url
}

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

output "france_cloudwatch_dashboard_url" {
  description = "URL du dashboard CloudWatch France"
  value       = module.france_prod.cloudwatch_dashboard_url
}

output "france_cloudwatch_sns_topic_arn" {
  description = "ARN du topic SNS pour les alertes France"
  value       = module.france_prod.cloudwatch_sns_topic_arn
}

# Germany outputs (décommenter avec germany_prod)
# output "germany_alb_url" {
#   value = module.germany_prod.alb_url
# }
# output "germany_eks_cluster_name" {
#   value = module.germany_prod.eks_cluster_name
# }
# output "germany_eks_kubeconfig_command" {
#   value = module.germany_prod.eks_kubeconfig_command
# }

# Sweden outputs (décommenter avec sweden_prod)
# output "sweden_alb_url" {
#   value = module.sweden_prod.alb_url
# }
# output "sweden_eks_cluster_name" {
#   value = module.sweden_prod.eks_cluster_name
# }
# output "sweden_eks_kubeconfig_command" {
#   value = module.sweden_prod.eks_kubeconfig_command
# }

# S3 Global
output "s3_bucket_name" {
  description = "Nom du bucket S3 partagé pour les assets Medusa"
  value       = module.s3_global.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN du bucket S3"
  value       = module.s3_global.bucket_arn
}

output "s3_iam_policy_arn" {
  description = "ARN de la policy IAM pour accès S3"
  value       = module.s3_global.iam_policy_arn
}

output "deployment_complete" {
  value = <<-EOT
    ==========================================
    DEPLOIEMENT TERRAFORM TERMINE !
    ==========================================

    FRANCE (eu-west-2):
       ALB:        ${module.france_prod.alb_url}
       App 1:      ${module.france_prod.app_instance_1_public_ip}
       App 2:      ${module.france_prod.app_instance_2_public_ip}
       DB Primary: ${module.france_prod.database_primary_public_ip}
       EKS:        ${module.france_prod.eks_cluster_name}

    S3 STORAGE:
       Bucket: ${module.s3_global.bucket_name}
       Region: eu-west-1 (Ireland)

    PROCHAINES ETAPES (EKS) :
       aws eks update-kubeconfig --region eu-west-3 --name ${module.france_prod.eks_cluster_name}
       kubectl apply -f ../k8s/

    ACCES :
       Backend:    via kubectl get svc -n medusa (port 9000)
       Storefront: via kubectl get svc -n medusa (port 8000)
    ==========================================
  EOT
}
