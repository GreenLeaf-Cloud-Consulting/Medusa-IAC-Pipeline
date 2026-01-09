output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = data.aws_subnets.public.ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = data.aws_subnets.private.ids
}

output "availability_zones" {
  description = "List of availability zones"
  value       = data.aws_subnet.default[*].availability_zone
}