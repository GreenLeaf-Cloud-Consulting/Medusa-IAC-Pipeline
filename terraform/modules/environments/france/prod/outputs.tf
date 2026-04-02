# France Production - Outputs

# ==================== EKS ====================
output "eks_cluster_name" {
  description = "Nom du cluster EKS France"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint du cluster EKS France"
  value       = module.eks.cluster_endpoint
}

output "eks_kubeconfig_command" {
  description = "Commande kubectl pour le cluster EKS France"
  value       = "aws eks update-kubeconfig --region eu-west-3 --name ${module.eks.cluster_name}"
}

# ==================== VPC ====================
output "vpc_id" {
  description = "VPC ID France"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Subnet IDs publics France (3 AZs)"
  value       = module.vpc.public_subnet_ids
}
