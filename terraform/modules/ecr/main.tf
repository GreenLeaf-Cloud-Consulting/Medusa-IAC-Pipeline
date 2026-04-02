resource "aws_ecr_repository" "backend" {
  name                 = "${var.personal_prefix}-${var.environment}-medusa-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.personal_prefix}-${var.environment}-medusa-backend"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    ManagedBy   = "Terraform"
  }
}

resource "aws_ecr_repository" "storefront" {
  name                 = "${var.personal_prefix}-${var.environment}-medusa-storefront"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.personal_prefix}-${var.environment}-medusa-storefront"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    ManagedBy   = "Terraform"
  }
}
