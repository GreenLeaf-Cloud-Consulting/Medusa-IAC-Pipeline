output "backend_repository_url" {
  description = "URL du dépôt ECR pour le backend Medusa"
  value       = aws_ecr_repository.backend.repository_url
}

output "storefront_repository_url" {
  description = "URL du dépôt ECR pour le storefront Medusa"
  value       = aws_ecr_repository.storefront.repository_url
}

output "registry_id" {
  description = "ID du registre ECR (AWS Account ID)"
  value       = aws_ecr_repository.backend.registry_id
}
