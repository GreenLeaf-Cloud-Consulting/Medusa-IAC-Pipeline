output "vpc_id" {
  description = "ID du VPC créé"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Liste des IDs des subnets publics"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Liste des IDs des subnets (publics utilisés pour simplifier)"
  value       = aws_subnet.public[*].id
}

output "availability_zones" {
  description = "Liste des availability zones utilisées"
  value       = aws_subnet.public[*].availability_zone
}

output "internet_gateway_id" {
  description = "ID de l'Internet Gateway"
  value       = aws_internet_gateway.main.id
}
