# France Production - Outputs

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
output "database_primary_id" {
  description = "Instance ID of Primary Database"
  value       = module.database_primary.primary_instance_id
}

output "database_primary_private_ip" {
  description = "Private IP of Primary Database"
  value       = module.database_primary.primary_instance_private_ip
}

output "database_primary_public_ip" {
  description = "Public IP of Primary Database"
  value       = module.database_primary.primary_eip
}

output "database_replica_france_ids" {
  description = "Instance IDs of France Replica Database"
  value       = module.database_replica_france.replica_instance_ids
}

output "database_replica_france_private_ips" {
  description = "Private IPs of France Replica Database"
  value       = module.database_replica_france.replica_instance_private_ips
}

output "database_replica_france_public_ips" {
  description = "Public IPs of France Replica Database"
  value       = module.database_replica_france.replica_instance_public_ips
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
    primary = {
      id         = module.database_primary.primary_instance_id
      public_ip  = module.database_primary.primary_eip
      private_ip = module.database_primary.primary_instance_private_ip
    }
    replica_france = {
      ids         = module.database_replica_france.replica_instance_ids
      private_ips = module.database_replica_france.replica_instance_private_ips
      public_ips  = module.database_replica_france.replica_instance_public_ips
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
  value       = module.database_primary.ssh_private_key_pem
  sensitive   = true
}

# ==================== MONITORING ====================
output "sns_topic_arn" {
  description = "ARN du SNS Topic pour les alarmes CloudWatch"
  value       = aws_sns_topic.cloudwatch_alarms.arn
}

output "lambda_function_name" {
  description = "Nom de la fonction Lambda pour les notifications Discord"
  value       = aws_lambda_function.discord_notifier.function_name
}

output "cloudwatch_alarms" {
  description = "Noms des alarmes CloudWatch configurées"
  value = {
    app1_high_cpu             = aws_cloudwatch_metric_alarm.app1_high_cpu.alarm_name
    app2_high_cpu             = aws_cloudwatch_metric_alarm.app2_high_cpu.alarm_name
    db_primary_high_cpu       = aws_cloudwatch_metric_alarm.db_primary_high_cpu.alarm_name
    db_replica_france_high_cpu = aws_cloudwatch_metric_alarm.db_replica_france_high_cpu.alarm_name
  }
}
