# Application Load Balancer Module
# Crée un ALB pour distribuer le trafic vers Online Boutique

resource "aws_lb" "main" {
  name               = "${var.environment}-${var.region_name}-alb-rayane"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name        = "${var.environment}-${var.region_name}-alb-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    Region      = var.region_name
    ManagedBy   = "Terraform"
  }
}

# Security Group pour l'ALB
resource "aws_security_group" "alb" {
  name        = "${var.environment}-${var.region_name}-alb-sg-rayane"
  description = "Security group for ${var.environment} ALB in ${var.region_name}"
  vpc_id      = var.vpc_id

  # HTTP
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound vers les instances
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-alb-sg-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
  }
}

# Target Group pour le backend
resource "aws_lb_target_group" "backend" {
  name     = "${var.environment}-${var.region_name}-medusa-tg-rayane"
  port     = var.backend_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-medusa-tg-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
  }
}

# Target Group pour Storefront (optionnel)
resource "aws_lb_target_group" "storefront" {
  count = var.enable_storefront ? 1 : 0

  name     = "${var.environment}-${var.region_name}-storefront-tg-rayane"
  port     = var.storefront_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.environment}-${var.region_name}-storefront-tg-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
  }
}

# Listener HTTP (redirect vers HTTPS en production)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = var.enable_https_redirect ? "redirect" : "forward"

    # Si HTTPS est activé, rediriger
    dynamic "redirect" {
      for_each = var.enable_https_redirect ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    # Sinon, forward vers le target group
    target_group_arn = var.enable_https_redirect ? null : aws_lb_target_group.backend.arn
  }
}

# Listener HTTPS (optionnel, nécessite un certificat ACM)
resource "aws_lb_listener" "https" {
  count = var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# Règle de routing pour le storefront (si activé)
resource "aws_lb_listener_rule" "storefront" {
  count = var.enable_storefront && var.enable_https ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.storefront[0].arn
  }

  condition {
    path_pattern {
      values = ["/store/*"]
    }
  }
}
