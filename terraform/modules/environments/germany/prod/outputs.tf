# Germany Production - Outputs

# ==================== ALB ====================
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "URL to access the application via ALB"
  value       = "http://${module.alb.alb_dns_name}"
}

# ==================== APP INSTANCES ====================
output "app_instance_1_id" {
  description = "Instance ID of App 1"
  value       = module.app_instance_1.instance_id
}

output "app_instance_1_private_ip" {
  description = "Private IP of App 1"
  value       = module.app_instance_1.instance_private_ip
}

output "app_instance_1_public_ip" {
  description = "Public IP of App 1"
  value       = module.app_instance_1.instance_ip
}

output "app_instance_2_id" {
  description = "Instance ID of App 2"
  value       = module.app_instance_2.instance_id
}

output "app_instance_2_private_ip" {
  description = "Private IP of App 2"
  value       = module.app_instance_2.instance_private_ip
}

output "app_instance_2_public_ip" {
  description = "Public IP of App 2"
  value       = module.app_instance_2.instance_ip
}

# ==================== DATABASE ====================
output "database_replica_germany_ids" {
  description = "Instance IDs of Germany Replica Database"
  value       = module.database_replica_germany.replica_instance_ids
}

output "database_replica_germany_private_ips" {
  description = "Private IPs of Germany Replica Database"
  value       = module.database_replica_germany.replica_instance_private_ips
}

# ==================== CONNECTION INFO ====================
output "app_instances_info" {
  description = "Information about all app instances"
  value = {
    app_1 = {
      id         = module.app_instance_1.instance_id
      public_ip  = module.app_instance_1.instance_ip
      private_ip = module.app_instance_1.instance_private_ip
    }
    app_2 = {
      id         = module.app_instance_2.instance_id
      public_ip  = module.app_instance_2.instance_ip
      private_ip = module.app_instance_2.instance_private_ip
    }
  }
}

output "database_info" {
  description = "Information about all database instances"
  value = {
    replica_germany = {
      ids         = module.database_replica_germany.replica_instance_ids
      private_ips = module.database_replica_germany.replica_instance_private_ips
    }
  }
}

# ==================== SSH KEYS ====================
output "app_1_ssh_private_key" {
  description = "SSH private key for App Instance 1"
  value       = module.app_instance_1.ssh_private_key
  sensitive   = true
}

output "app_2_ssh_private_key" {
  description = "SSH private key for App Instance 2"
  value       = module.app_instance_2.ssh_private_key
  sensitive   = true
}

output "database_ssh_private_key" {
  description = "SSH private key for Database instances"
  value       = module.database_replica_germany.ssh_private_key_pem
  sensitive   = true
}
