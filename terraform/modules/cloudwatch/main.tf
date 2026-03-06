# ==========================================
# CLOUDWATCH MODULE - Monitoring complet Medusa
# ==========================================

# ==================== SNS TOPIC + EMAIL ====================

resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-${var.region_name}-alerts-rayane"

  tags = {
    Name        = "${var.environment}-${var.region_name}-alerts-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
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
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

# ==================== ALARMES NETWORK IN ====================

resource "aws_cloudwatch_metric_alarm" "ec2_network_in" {
  count = length(var.instance_ids)

  alarm_name          = "${var.environment}-${var.region_name}-${var.instance_names[count.index]}-network-in-rayane"
  alarm_description   = "Network In > ${var.network_in_threshold} bytes sur ${var.instance_names[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Sum"
  threshold           = var.network_in_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }

  alarm_actions             = [aws_sns_topic.alerts.arn]
  insufficient_data_actions = []

  tags = {
    Name        = "${var.environment}-${var.region_name}-${var.instance_names[count.index]}-network-in-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

# ==================== ALARMES NETWORK OUT ====================

resource "aws_cloudwatch_metric_alarm" "ec2_network_out" {
  count = length(var.instance_ids)

  alarm_name          = "${var.environment}-${var.region_name}-${var.instance_names[count.index]}-network-out-rayane"
  alarm_description   = "Network Out > ${var.network_out_threshold} bytes sur ${var.instance_names[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Sum"
  threshold           = var.network_out_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }

  alarm_actions             = [aws_sns_topic.alerts.arn]
  insufficient_data_actions = []

  tags = {
    Name        = "${var.environment}-${var.region_name}-${var.instance_names[count.index]}-network-out-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

# ==================== ALARMES EBS WRITE OPS ====================

resource "aws_cloudwatch_metric_alarm" "ec2_ebs_write_ops" {
  count = length(var.instance_ids)

  alarm_name          = "${var.environment}-${var.region_name}-${var.instance_names[count.index]}-ebs-write-ops-rayane"
  alarm_description   = "EBS Write Ops > ${var.ebs_write_ops_threshold} IOPS sur ${var.instance_names[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EBSWriteOps"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Sum"
  threshold           = var.ebs_write_ops_threshold
  unit                = "Count"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }

  alarm_actions             = [aws_sns_topic.alerts.arn]
  insufficient_data_actions = []

  tags = {
    Name        = "${var.environment}-${var.region_name}-${var.instance_names[count.index]}-ebs-write-ops-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

# ==================== ALARMES EBS WRITE BYTES ====================

resource "aws_cloudwatch_metric_alarm" "ec2_ebs_write_bytes" {
  count = length(var.instance_ids)

  alarm_name          = "${var.environment}-${var.region_name}-${var.instance_names[count.index]}-ebs-write-bytes-rayane"
  alarm_description   = "EBS Write Bytes > ${var.ebs_write_bytes_threshold} bytes sur ${var.instance_names[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EBSWriteBytes"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Sum"
  threshold           = var.ebs_write_bytes_threshold
  unit                = "Bytes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }

  alarm_actions             = [aws_sns_topic.alerts.arn]
  insufficient_data_actions = []

  tags = {
    Name        = "${var.environment}-${var.region_name}-${var.instance_names[count.index]}-ebs-write-bytes-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

# ==================== ALARMES STATUS CHECK FAILED ====================

resource "aws_cloudwatch_metric_alarm" "ec2_status_check_failed" {
  count = length(var.instance_ids)

  alarm_name          = "${var.environment}-${var.region_name}-${var.instance_names[count.index]}-status-check-failed-rayane"
  alarm_description   = "Status check failed sur ${var.instance_names[count.index]}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 1
  unit                = "Count"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }

  alarm_actions             = [aws_sns_topic.alerts.arn]
  insufficient_data_actions = []

  tags = {
    Name        = "${var.environment}-${var.region_name}-${var.instance_names[count.index]}-status-check-failed-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

# ==================== LAMBDA DISCORD (conditionnel) ====================

data "aws_iam_policy_document" "lambda_assume_role" {
  count = var.enable_discord_notifications ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  count = var.enable_discord_notifications ? 1 : 0

  name               = "${var.environment}-${var.region_name}-lambda-discord-role-rayane"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[0].json

  tags = {
    Name        = "${var.environment}-${var.region_name}-lambda-discord-role-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_policy" "lambda_logging" {
  count = var.enable_discord_notifications ? 1 : 0

  name        = "${var.environment}-${var.region_name}-lambda-logging-policy-rayane"
  description = "Allow Lambda to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  count = var.enable_discord_notifications ? 1 : 0

  role       = aws_iam_role.lambda_role[0].name
  policy_arn = aws_iam_policy.lambda_logging[0].arn
}

data "archive_file" "lambda_zip" {
  count = var.enable_discord_notifications ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/lambda/send_discord_alarm.py"
  output_path = "${path.module}/lambda/function.zip"
}

resource "aws_lambda_function" "discord_notifier" {
  count = var.enable_discord_notifications ? 1 : 0

  filename         = data.archive_file.lambda_zip[0].output_path
  function_name    = "${var.environment}-${var.region_name}-discord-alarm-rayane"
  role             = aws_iam_role.lambda_role[0].arn
  handler          = "send_discord_alarm.handler"
  source_code_hash = data.archive_file.lambda_zip[0].output_base64sha256
  runtime          = "python3.11"

  environment {
    variables = {
      DISCORD_WEBHOOK = var.discord_webhook
    }
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-discord-alarm-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

resource "aws_lambda_permission" "allow_sns" {
  count = var.enable_discord_notifications ? 1 : 0

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

resource "aws_sns_topic_subscription" "lambda" {
  count = var.enable_discord_notifications ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.discord_notifier[0].arn
}

# ==================== BUDGET (conditionnel) ====================

resource "aws_budgets_budget" "monthly_budget" {
  count = var.enable_budget ? 1 : 0

  name              = "${var.environment}-${var.region_name}-budget-mensuel-rayane"
  budget_type       = "COST"
  limit_amount      = var.budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2025-01-01_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-budget-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

# ==================== DASHBOARD ====================

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-${var.region_name}-dashboard-rayane"

  dashboard_body = jsonencode({
    widgets = flatten([
      [{
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "## Medusa Infrastructure - ${upper(var.region_name)} | Monitoring Complet"
        }
      }],
      [for i, name in var.instance_names : {
        type   = "metric"
        x      = (i % 2) * 12
        y      = 1 + floor(i / 2) * 6
        width  = 12
        height = 6
        properties = {
          title  = "CPU - ${name}"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [[
            "AWS/EC2", "CPUUtilization",
            "InstanceId", var.instance_ids[i]
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
      }],
      [{
        type   = "metric"
        x      = 12
        y      = 1 + ceil(length(var.instance_names) / 2) * 6
        width  = 12
        height = 6
        properties = {
          title   = "Status Check Failed"
          view    = "singleValue"
          region  = var.aws_region
          metrics = [for i, id in var.instance_ids : ["AWS/EC2", "StatusCheckFailed", "InstanceId", id]]
          period  = 300
          stat    = "Maximum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 12
        height = 6
        properties = {
          title = "Network Traffic"
          view  = "timeSeries"
          region = var.aws_region
          metrics = concat([
            for id in var.instance_ids : ["AWS/EC2", "NetworkIn", "InstanceId", id]
          ], [
            for id in var.instance_ids : ["AWS/EC2", "NetworkOut", "InstanceId", id]
          ])
          period = 300
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 13
        width  = 12
        height = 6
        properties = {
          title = "EBS Write Operations & Bytes"
          view  = "timeSeries"
          region = var.aws_region
          metrics = concat([
            for id in var.instance_ids : ["AWS/EC2", "EBSWriteOps", "InstanceId", id]
          ], [
            for id in var.instance_ids : ["AWS/EC2", "EBSWriteBytes", "InstanceId", id]
          ])
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 19
        width  = 24
        height = 6
        properties = {
          title = "État des alarmes"
          alarms = concat(
            [for alarm in aws_cloudwatch_metric_alarm.ec2_cpu_high : alarm.arn],
            [for alarm in aws_cloudwatch_metric_alarm.ec2_network_in : alarm.arn],
            [for alarm in aws_cloudwatch_metric_alarm.ec2_network_out : alarm.arn],
            [for alarm in aws_cloudwatch_metric_alarm.ec2_ebs_write_ops : alarm.arn],
            [for alarm in aws_cloudwatch_metric_alarm.ec2_ebs_write_bytes : alarm.arn],
            [for alarm in aws_cloudwatch_metric_alarm.ec2_status_check_failed : alarm.arn]
          )
        }
      }]
    ])
  })
}
