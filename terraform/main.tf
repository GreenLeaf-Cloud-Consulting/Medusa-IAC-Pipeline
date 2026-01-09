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
  source = "./modules/environments/france/prod"
}

# ==================== GERMANY PRODUCTION ====================
module "germany_prod" {
  source = "./modules/environments/germany/prod"
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

    📝 Prochaine étape:
       cd ansible && ansible-playbook -i inventory/hosts.yml site.yml

    🔑 Clés SSH sauvegardées dans: terraform/keys/
    ==========================================
  EOT
}
