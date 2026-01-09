output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.medusa_assets.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.medusa_assets.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.medusa_assets.bucket_regional_domain_name
}

output "iam_policy_arn" {
  description = "ARN of the IAM policy for S3 access"
  value       = aws_iam_policy.s3_medusa_access.arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role (if created)"
  value       = var.create_iam_role ? aws_iam_role.medusa_s3_role[0].arn : null
}

output "instance_profile_name" {
  description = "Name of the instance profile (if created)"
  value       = var.create_iam_role ? aws_iam_instance_profile.medusa_s3_profile[0].name : null
}
