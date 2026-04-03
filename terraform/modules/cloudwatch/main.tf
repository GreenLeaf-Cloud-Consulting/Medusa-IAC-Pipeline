# ==========================================
# CLOUDWATCH MODULE - Container Insights EKS
# Surveille les pods, nodes et métriques EKS
# ==========================================

# ==================== SNS TOPIC + EMAIL ====================

resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-${var.region_name}-alerts-rayane"

  tags = {
    Name        = "${var.environment}-${var.region_name}-alerts-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    ManagedBy   = "Terraform"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ==================== LOG GROUPS EKS ====================

resource "aws_cloudwatch_log_group" "eks_application" {
  name              = "/aws/containerinsights/${var.eks_cluster_name}/application"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "eks_performance" {
  name              = "/aws/containerinsights/${var.eks_cluster_name}/performance"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ==================== ALARMES EKS NODES ====================

resource "aws_cloudwatch_metric_alarm" "node_cpu_high" {
  alarm_name          = "${var.environment}-${var.region_name}-node-cpu-high-rayane"
  alarm_description   = "CPU nodes EKS > ${var.cpu_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.eks_cluster_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "node_memory_high" {
  alarm_name          = "${var.environment}-${var.region_name}-node-memory-high-rayane"
  alarm_description   = "Mémoire nodes EKS > ${var.memory_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.eks_cluster_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "pod_restarts" {
  alarm_name          = "${var.environment}-${var.region_name}-pod-restarts-rayane"
  alarm_description   = "Redémarrages de pods anormaux sur le cluster"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "pod_number_of_container_restarts"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.eks_cluster_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ==================== DASHBOARD EKS ====================

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-${var.region_name}-eks-dashboard-rayane"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "## Online Boutique - EKS Container Insights | ${upper(var.region_name)}"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "CPU Nodes (%)"
          view    = "timeSeries"
          region  = var.aws_region
          metrics = [["ContainerInsights", "node_cpu_utilization", "ClusterName", var.eks_cluster_name]]
          period  = 300
          stat    = "Average"
          yAxis   = { left = { min = 0, max = 100 } }
          annotations = {
            horizontal = [{ label = "Seuil", value = var.cpu_threshold, color = "#ff0000" }]
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "Mémoire Nodes (%)"
          view    = "timeSeries"
          region  = var.aws_region
          metrics = [["ContainerInsights", "node_memory_utilization", "ClusterName", var.eks_cluster_name]]
          period  = 300
          stat    = "Average"
          yAxis   = { left = { min = 0, max = 100 } }
          annotations = {
            horizontal = [{ label = "Seuil", value = var.memory_threshold, color = "#ff0000" }]
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "Pods Running"
          view    = "timeSeries"
          region  = var.aws_region
          metrics = [["ContainerInsights", "pod_number_of_running_containers", "ClusterName", var.eks_cluster_name]]
          period  = 60
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          title   = "Redémarrages de pods"
          view    = "timeSeries"
          region  = var.aws_region
          metrics = [["ContainerInsights", "pod_number_of_container_restarts", "ClusterName", var.eks_cluster_name]]
          period  = 300
          stat    = "Sum"
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
          alarms = [
            aws_cloudwatch_metric_alarm.node_cpu_high.arn,
            aws_cloudwatch_metric_alarm.node_memory_high.arn,
            aws_cloudwatch_metric_alarm.pod_restarts.arn
          ]
        }
      }
    ]
  })
}
