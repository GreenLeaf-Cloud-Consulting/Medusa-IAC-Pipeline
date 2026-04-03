output "sns_topic_arn" {
  description = "ARN du topic SNS pour les alertes"
  value       = aws_sns_topic.alerts.arn
}

output "alarm_arns" {
  description = "ARNs des alarmes CloudWatch"
  value = [
    aws_cloudwatch_metric_alarm.node_cpu_high.arn,
    aws_cloudwatch_metric_alarm.node_memory_high.arn,
    aws_cloudwatch_metric_alarm.pod_restarts.arn
  ]
}

output "dashboard_name" {
  description = "Nom du dashboard CloudWatch"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "URL du dashboard CloudWatch"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
