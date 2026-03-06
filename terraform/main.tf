# ==========================================
# MAIN TERRAFORM CONFIGURATION - V2
# Architecture complète multi-région avec ALB
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
  source                 = "./modules/environments/france/prod"
  discord_webhook        = var.discord_webhook
  grafana_admin_password = var.grafana_admin_password
}

# ==================== GERMANY PRODUCTION ====================
module "germany_prod" {
  source                 = "./modules/environments/germany/prod"
  discord_webhook        = var.discord_webhook
  grafana_admin_password = var.grafana_admin_password
}

# ==================== SWEDEN PRODUCTION ====================
module "sweden_prod" {
  source                 = "./modules/environments/sweden/prod"
  discord_webhook        = var.discord_webhook
  grafana_admin_password = var.grafana_admin_password
}

# ==================== SHARED S3 BUCKET ====================
# Bucket S3 global partagé entre France, Germany et Sweden pour les assets Medusa
module "s3_global" {
  source = "./modules/s3"

  # On utilise eu-west-1 (Irlande) comme région neutre
  providers = {
    aws = aws.ireland
  }

  personal_prefix = var.personal_prefix
  environment     = "prod"
  region_short    = "global"

  enable_versioning = true
  cors_allowed_origins = [
    "http://${module.france_prod.alb_url}",
    "http://${module.germany_prod.alb_url}",
    "http://${module.sweden_prod.alb_url}",
    "http://localhost:9000",
    "http://localhost:7001"
  ]

  create_iam_role = true
}

# Provider pour le bucket S3 (région neutre)
provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}

# ==========================================
# OUTPUTS - Informations de connexion
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

# Germany
output "germany_alb_url" {
  description = "URL de l'ALB Germany"
  value       = module.germany_prod.alb_url
}

output "germany_app_instances" {
  description = "Instances App Germany"
  value       = module.germany_prod.app_instances_info
}

output "germany_database" {
  description = "Instances Database Germany"
  value       = module.germany_prod.database_info
}

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

# EKS France
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

# EKS Germany
output "germany_eks_cluster_name" {
  description = "Nom du cluster EKS Germany"
  value       = module.germany_prod.eks_cluster_name
}

output "germany_eks_cluster_endpoint" {
  description = "Endpoint du cluster EKS Germany"
  value       = module.germany_prod.eks_cluster_endpoint
}

output "germany_eks_kubeconfig_command" {
  description = "Commande kubectl pour le cluster EKS Germany"
  value       = module.germany_prod.eks_kubeconfig_command
}

# Sweden
output "sweden_alb_url" {
  description = "URL de l'ALB Sweden"
  value       = module.sweden_prod.alb_url
}

output "sweden_app_instances" {
  description = "Instances App Sweden"
  value       = module.sweden_prod.app_instances_info
}

output "sweden_database" {
  description = "Instances Database Sweden"
  value       = module.sweden_prod.database_info
}

output "sweden_eks_cluster_name" {
  description = "Nom du cluster EKS Sweden"
  value       = module.sweden_prod.eks_cluster_name
}

output "sweden_eks_kubeconfig_command" {
  description = "Commande kubectl pour le cluster EKS Sweden"
  value       = module.sweden_prod.eks_kubeconfig_command
}

# CloudWatch France
output "france_cloudwatch_dashboard_url" {
  description = "URL du dashboard CloudWatch France"
  value       = module.france_prod.cloudwatch_dashboard_url
}

output "france_cloudwatch_sns_topic_arn" {
  description = "ARN du topic SNS pour les alertes France"
  value       = module.france_prod.cloudwatch_sns_topic_arn
}

# CloudWatch Germany
output "germany_cloudwatch_dashboard_url" {
  description = "URL du dashboard CloudWatch Germany"
  value       = module.germany_prod.cloudwatch_dashboard_url
}

output "germany_cloudwatch_sns_topic_arn" {
  description = "ARN du topic SNS pour les alertes Germany"
  value       = module.germany_prod.cloudwatch_sns_topic_arn
}

# CloudWatch Sweden
output "sweden_cloudwatch_dashboard_url" {
  description = "URL du dashboard CloudWatch Sweden"
  value       = module.sweden_prod.cloudwatch_dashboard_url
}

output "sweden_cloudwatch_sns_topic_arn" {
  description = "ARN du topic SNS pour les alertes Sweden"
  value       = module.sweden_prod.cloudwatch_sns_topic_arn
}

# Monitoring - Grafana & Prometheus
output "france_grafana_url" {
  description = "Grafana URL France"
  value       = module.france_prod.grafana_url
}

output "france_prometheus_url" {
  description = "Prometheus URL France"
  value       = module.france_prod.prometheus_url
}

output "germany_grafana_url" {
  description = "Grafana URL Germany"
  value       = module.germany_prod.grafana_url
}

output "germany_prometheus_url" {
  description = "Prometheus URL Germany"
  value       = module.germany_prod.prometheus_url
}

output "sweden_grafana_url" {
  description = "Grafana URL Sweden"
  value       = module.sweden_prod.grafana_url
}

output "sweden_prometheus_url" {
  description = "Prometheus URL Sweden"
  value       = module.sweden_prod.prometheus_url
}

# ==========================================
# ANSIBLE INVENTORY GENERATION
# ==========================================

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/ansible-inventory.tpl", {
    # France App Instances
    france_app_1_public_ip  = module.france_prod.app_instance_1_public_ip
    france_app_1_private_ip = module.france_prod.app_instance_1_private_ip
    france_app_2_public_ip  = module.france_prod.app_instance_2_public_ip
    france_app_2_private_ip = module.france_prod.app_instance_2_private_ip

    # France Database
    france_db_primary_public_ip  = module.france_prod.database_primary_public_ip
    france_db_primary_private_ip = module.france_prod.database_primary_private_ip
    france_db_replica_private_ips = module.france_prod.database_replica_france_private_ips
    france_db_replica_public_ips = module.france_prod.database_replica_france_public_ips

    # Germany App Instances
    germany_app_1_public_ip  = module.germany_prod.app_instance_1_public_ip
    germany_app_1_private_ip = module.germany_prod.app_instance_1_private_ip
    germany_app_2_public_ip  = module.germany_prod.app_instance_2_public_ip
    germany_app_2_private_ip = module.germany_prod.app_instance_2_private_ip

    # Germany Database
    germany_db_replica_private_ips = module.germany_prod.database_replica_germany_private_ips
    germany_db_replica_public_ips = module.germany_prod.database_replica_germany_public_ips

    # Configuration
    ssh_user  = "admin"
    keys_path = "../keys"

    # AWS Regions
    france_aws_region  = "eu-west-2"
    germany_aws_region = "eu-central-1"
  })

  filename        = "${path.module}/ansible/inventory/hosts.yml"
  file_permission = "0644"
}

# ==========================================
# SAVE SSH KEYS
# ==========================================
# NOTE: Les clés SSH sont maintenant créées directement par les modules
# ec2-instance et database dans le répertoire keys/

output "deployment_complete" {
  value = <<-EOT
    ==========================================
    🚀 DÉPLOIEMENT TERRAFORM TERMINÉ !
    ==========================================

    📍 FRANCE (eu-west-2 - London):
       ALB: ${module.france_prod.alb_url}
       App 1: ${module.france_prod.app_instance_1_public_ip}
       App 2: ${module.france_prod.app_instance_2_public_ip}
       DB Primary: ${module.france_prod.database_primary_public_ip}

    📍 GERMANY (eu-central-1):
       ALB: ${module.germany_prod.alb_url}
       App 1: ${module.germany_prod.app_instance_1_public_ip}
       App 2: ${module.germany_prod.app_instance_2_public_ip}

    🪣 S3 STORAGE (Partagé entre France et Germany):
       Bucket: ${module.s3_global.bucket_name}
       Region: eu-west-1 (Ireland)

    📝 Prochaine étape:
       cd ansible && ansible-playbook -i inventory/hosts.yml site.yml

    🔑 Clés SSH sauvegardées dans: terraform/keys/
    ==========================================
  EOT
}
