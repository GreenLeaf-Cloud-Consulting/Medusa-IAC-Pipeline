resource "aws_security_group" "instance_sg" {
  name_prefix = "${var.environment}-${var.instance_name}-app-sg-"
  description = "Security group for ${var.environment} ${var.instance_name} app instance"
  vpc_id      = var.vpc_id

  # SSH - Pour l'administration
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Traffic depuis l'ALB - Backend
  ingress {
    description     = "HTTP from ALB"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Storefront depuis l'ALB
  ingress {
    description     = "Storefront from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Outbound - Tout autorisé
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.instance_name}-app-sg"
    Environment = var.environment
  }
}
