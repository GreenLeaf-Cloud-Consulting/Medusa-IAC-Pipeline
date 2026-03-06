# Sweden Production - Outputs

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
  value = module.app_instance_1.instance_id
}

output "app_instance_1_public_ip" {
  value = module.app_instance_1.instance_ip
}

output "app_instance_1_private_ip" {
  value = module.app_instance_1.instance_private_ip
}

output "app_instance_2_id" {
  value = module.app_instance_2.instance_id
}

output "app_instance_2_public_ip" {
  value = module.app_instance_2.instance_ip
}

output "app_instance_2_private_ip" {
  value = module.app_instance_2.instance_private_ip
}

# ==================== DATABASE ====================
output "database_replica_sweden_ids" {
  value = module.database_replica_sweden.replica_instance_ids
}

output "database_replica_sweden_private_ips" {
  value = module.database_replica_sweden.replica_instance_private_ips
}

output "database_replica_sweden_public_ips" {
  value = module.database_replica_sweden.replica_instance_public_ips
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
  description = "Information about database instances"
  value = {
    replica_sweden = {
      ids         = module.database_replica_sweden.replica_instance_ids
      private_ips = module.database_replica_sweden.replica_instance_private_ips
      public_ips  = module.database_replica_sweden.replica_instance_public_ips
    }
  }
}

# ==================== SSH KEYS ====================
output "app_1_ssh_private_key" {
  value     = module.app_instance_1.ssh_private_key
  sensitive = true
}

output "app_2_ssh_private_key" {
  value     = module.app_instance_2.ssh_private_key
  sensitive = true
}

output "database_ssh_private_key" {
  value     = module.database_replica_sweden.ssh_private_key_pem
  sensitive = true
}

# ==================== EKS ====================
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  value = module.eks.cluster_arn
}

output "eks_node_group_status" {
  value = module.eks.node_group_status
}

output "eks_kubeconfig_command" {
  value = module.eks.kubeconfig_command
}

# ==================== CLOUDWATCH ====================
output "cloudwatch_sns_topic_arn" {
  description = "ARN du topic SNS pour les alertes"
  value       = module.cloudwatch.sns_topic_arn
}

output "cloudwatch_dashboard_url" {
  description = "URL du dashboard CloudWatch"
  value       = module.cloudwatch.dashboard_url
}

output "cloudwatch_alarm_arns" {
  description = "ARNs des alarmes CloudWatch"
  value       = module.cloudwatch.alarm_arns
}

# ==================== MONITORING ====================
output "grafana_url" {
  description = "Grafana web UI URL"
  value       = module.monitoring.grafana_url
}

output "prometheus_url" {
  description = "Prometheus web UI URL"
  value       = module.monitoring.prometheus_url
}

output "monitoring_public_ip" {
  description = "Public IP of the monitoring server"
  value       = module.monitoring.monitoring_public_ip
}
