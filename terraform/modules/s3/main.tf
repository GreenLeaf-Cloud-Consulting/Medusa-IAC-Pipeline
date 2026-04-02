# S3 Bucket Module for Online Boutique Assets Storage

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_s3_bucket" "medusa_assets" {
  bucket = "${var.personal_prefix}-${var.environment}-medusa-assets-${var.region_short}"

  tags = {
    Name        = "${var.personal_prefix}-${var.environment}-medusa-assets-${var.region_short}"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "OnlineBoutique"
  }
}

# Block public access by default
resource "aws_s3_bucket_public_access_block" "medusa_assets" {
  bucket = aws_s3_bucket.medusa_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for asset protection
resource "aws_s3_bucket_versioning" "medusa_assets" {
  bucket = aws_s3_bucket.medusa_assets.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "medusa_assets" {
  bucket = aws_s3_bucket.medusa_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle rules (optional - uncomment if needed)
# resource "aws_s3_bucket_lifecycle_configuration" "medusa_assets" {
#   bucket = aws_s3_bucket.medusa_assets.id
#
#   rule {
#     id     = "delete-old-versions"
#     status = "Enabled"
#
#     noncurrent_version_expiration {
#       noncurrent_days = 90
#     }
#   }
# }

# CORS configuration for web access
resource "aws_s3_bucket_cors_configuration" "medusa_assets" {
  bucket = aws_s3_bucket.medusa_assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# IAM Policy for EC2 instances to access S3
resource "aws_iam_policy" "s3_medusa_access" {
  name        = "${var.personal_prefix}-${var.environment}-medusa-s3-access-${var.region_short}"
  description = "Allow app instances to access S3 bucket for assets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.medusa_assets.arn,
          "${aws_s3_bucket.medusa_assets.arn}/*"
        ]
      }
    ]
  })
}

# IAM Role for EC2 instances
resource "aws_iam_role" "medusa_s3_role" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.personal_prefix}-${var.environment}-medusa-s3-role-${var.region_short}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "medusa_s3_policy_attach" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.medusa_s3_role[0].name
  policy_arn = aws_iam_policy.s3_medusa_access.arn
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "medusa_s3_profile" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.personal_prefix}-${var.environment}-medusa-s3-profile-${var.region_short}"
  role  = aws_iam_role.medusa_s3_role[0].name
}
