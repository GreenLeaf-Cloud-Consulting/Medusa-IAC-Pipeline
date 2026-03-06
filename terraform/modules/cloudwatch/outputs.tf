output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.alerts.name
}

# --- CPU Alarms ---

output "alarm_cpu_arns" {
  description = "ARNs of all CPU CloudWatch alarms"
  value       = aws_cloudwatch_metric_alarm.ec2_cpu_high[*].arn
}

# --- Network Alarms ---

output "alarm_network_in_arns" {
  description = "ARNs of all Network In alarms"
  value       = aws_cloudwatch_metric_alarm.ec2_network_in[*].arn
}

output "alarm_network_out_arns" {
  description = "ARNs of all Network Out alarms"
  value       = aws_cloudwatch_metric_alarm.ec2_network_out[*].arn
}

# --- EBS Alarms ---

output "alarm_ebs_write_ops_arns" {
  description = "ARNs of all EBS Write Ops alarms"
  value       = aws_cloudwatch_metric_alarm.ec2_ebs_write_ops[*].arn
}

output "alarm_ebs_write_bytes_arns" {
  description = "ARNs of all EBS Write Bytes alarms"
  value       = aws_cloudwatch_metric_alarm.ec2_ebs_write_bytes[*].arn
}

# --- Status Check Alarms ---

output "alarm_status_check_failed_arns" {
  description = "ARNs of all Status Check Failed alarms"
  value       = aws_cloudwatch_metric_alarm.ec2_status_check_failed[*].arn
}

# --- All Alarms (combined) ---

output "alarm_arns" {
  description = "ARNs of all CloudWatch alarms"
  value = concat(
    aws_cloudwatch_metric_alarm.ec2_cpu_high[*].arn,
    aws_cloudwatch_metric_alarm.ec2_network_in[*].arn,
    aws_cloudwatch_metric_alarm.ec2_network_out[*].arn,
    aws_cloudwatch_metric_alarm.ec2_ebs_write_ops[*].arn,
    aws_cloudwatch_metric_alarm.ec2_ebs_write_bytes[*].arn,
    aws_cloudwatch_metric_alarm.ec2_status_check_failed[*].arn
  )
}

# --- Dashboard ---

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "URL to access the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

# --- Lambda Discord (conditionnel) ---

output "lambda_function_name" {
  description = "Name of the Lambda function for Discord notifications"
  value       = var.enable_discord_notifications ? aws_lambda_function.discord_notifier[0].function_name : ""
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = var.enable_discord_notifications ? aws_lambda_function.discord_notifier[0].arn : ""
}

# --- Budget (conditionnel) ---

output "budget_name" {
  description = "Name of the monthly budget"
  value       = var.enable_budget ? aws_budgets_budget.monthly_budget[0].name : ""
}
