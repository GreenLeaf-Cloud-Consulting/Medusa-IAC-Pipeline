# ==========================================
# CLOUDWATCH MODULE - Monitoring infrastructure Online Boutique
# ==========================================

# ==================== SNS TOPIC + EMAIL ====================

resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-${var.region_name}-alerts-rayane"

  tags = {
    Name        = "${var.environment}-${var.region_name}-alerts-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ==================== ALARMES CPU EC2 ====================

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  count = length(var.instance_ids)

  alarm_name          = "${var.environment}-${var.region_name}-${var.instance_names[count.index]}-cpu-high-rayane"
  alarm_description   = "CPU > ${var.cpu_threshold}% sur ${var.instance_names[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.environment}-${var.region_name}-${var.instance_names[count.index]}-cpu-high-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

# ==================== DASHBOARD ====================

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-${var.region_name}-dashboard-rayane"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "## Online Boutique Infrastructure - ${upper(var.region_name)} | CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 12
        height = 6
        properties = {
          title  = "CPU - App Instance 1"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [[
            "AWS/EC2", "CPUUtilization",
            "InstanceId", var.instance_ids[0]
          ]]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0, max = 100 }
          }
          annotations = {
            horizontal = [{
              label = "Seuil alarme"
              value = var.cpu_threshold
              color = "#ff0000"
            }]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 1
        width  = 12
        height = 6
        properties = {
          title  = "CPU - App Instance 2"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [[
            "AWS/EC2", "CPUUtilization",
            "InstanceId", var.instance_ids[1]
          ]]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0, max = 100 }
          }
          annotations = {
            horizontal = [{
              label = "Seuil alarme"
              value = var.cpu_threshold
              color = "#ff0000"
            }]
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          title  = "CPU - DB Primary"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [[
            "AWS/EC2", "CPUUtilization",
            "InstanceId", var.instance_ids[2]
          ]]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0, max = 100 }
          }
          annotations = {
            horizontal = [{
              label = "Seuil alarme"
              value = var.cpu_threshold
              color = "#ff0000"
            }]
          }
        }
      },
      {
        type   = "alarm"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          title  = "État des alarmes"
          alarms = [for alarm in aws_cloudwatch_metric_alarm.ec2_cpu_high : alarm.arn]
        }
      }
    ]
  })
}
