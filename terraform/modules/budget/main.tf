# ==========================================
# BUDGET MODULE - Alertes de coûts AWS
# FinOps : surveiller les dépenses cloud
# ==========================================

variable "team_name" {
  type    = string
  default = "rayane"
}

variable "monthly_budget_usd" {
  description = "Budget mensuel en USD"
  type        = number
  default     = 600
}

variable "alert_email" {
  description = "Email pour recevoir les alertes de budget"
  type        = string
}

# ==================== SNS TOPIC ====================
resource "aws_sns_topic" "budget_alerts" {
  name = "budget-alerts-${var.team_name}"

  tags = {
    Name      = "budget-alerts-${var.team_name}"
    ManagedBy = "Terraform"
  }
}

resource "aws_sns_topic_subscription" "budget_email" {
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ==================== BUDGET + ALERTES ====================

resource "aws_budgets_budget" "monthly" {
  name         = "black-friday-survival-${var.team_name}"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Alerte 1 : 70% du budget atteint → Warning
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 70
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # Alerte 2 : 90% du budget atteint → Critique
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # Alerte 3 : 100% du budget dépassé → Urgence
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # Alerte 4 : Prévision dépasse 100% → Anticipation
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

# ==================== OUTPUTS ====================
output "budget_name" {
  value = aws_budgets_budget.monthly.name
}

output "sns_topic_arn" {
  value = aws_sns_topic.budget_alerts.arn
}
