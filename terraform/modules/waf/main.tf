# ==========================================
# WAF MODULE - Web Application Firewall
# Protège l'ELB Online Boutique
# ==========================================

variable "environment" {
  type = string
}

variable "region_name" {
  type = string
}

variable "elb_arn" {
  description = "ARN de l'ALB à protéger (optionnel - nécessite un ALB, pas un Classic ELB)"
  type        = string
  default     = ""
}

# ==================== WAF ACL ====================
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.environment}-${var.region_name}-waf-rayane"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Règle 1 : Protection contre les IPs malveillantes connues (AWS Managed)
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  # Règle 2 : Protection OWASP Top 10 (AWS Managed)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Règle 3 : Protection SQL Injection (AWS Managed)
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Règle 4 : Rate limiting - max 2000 req/5min par IP
  rule {
    name     = "RateLimitPerIP"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitPerIP"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-waf-rayane"
    Environment = var.environment
    Application = "boutique"
    ManagedBy   = "Terraform"
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-${var.region_name}-waf"
    sampled_requests_enabled   = true
  }
}

# ==================== ASSOCIATION WAF → ELB ====================
resource "aws_wafv2_web_acl_association" "main" {
  count        = var.elb_arn != "" ? 1 : 0
  resource_arn = var.elb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# ==================== OUTPUTS ====================
output "waf_arn" {
  value = aws_wafv2_web_acl.main.arn
}

output "waf_id" {
  value = aws_wafv2_web_acl.main.id
}
