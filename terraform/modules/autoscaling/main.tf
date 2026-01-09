# ==========================================
# AUTO SCALING MODULE
# ==========================================

# Launch Template - Définit la configuration des instances EC2
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-${var.region}-medusa-app-"
  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated_key.key_name

  network_interfaces {
    associate_public_ip_address = var.enable_public_ip
    security_groups             = [aws_security_group.instance_sg.id]
    delete_on_termination       = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = false
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.environment}-${var.region}-medusa-app-asg"
      Project     = "greenleaf"
      Environment = var.environment
      Application = "medusa"
      Owner       = "equipe@greenleaf.com"
      CostCenter  = "ecommerce"
      Region      = var.region
      Role        = "medusa-app"
      ManagedBy   = "autoscaling"
    }
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    region      = var.region
    environment = var.environment
  }))

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                = "${var.environment}-${var.region}-medusa-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [var.alb_target_group_arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "${var.environment}-${var.region}-medusa-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "autoscaling"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# Scaling Policy - Scale UP (augmenter les instances)
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.environment}-${var.region}-medusa-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

# CloudWatch Alarm - Déclencheur Scale UP (CPU > 70%)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.environment}-${var.region}-medusa-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_description = "This metric monitors EC2 CPU utilization for scale up"
  alarm_actions     = [aws_autoscaling_policy.scale_up.arn]
}

# Scaling Policy - Scale DOWN (réduire les instances)
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.environment}-${var.region}-medusa-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

# CloudWatch Alarm - Déclencheur Scale DOWN (CPU < 30%)
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.environment}-${var.region}-medusa-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_description = "This metric monitors EC2 CPU utilization for scale down"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]
}

# Target Tracking Scaling Policy - Alternative recommandée
# Maintient automatiquement le CPU à 50%
resource "aws_autoscaling_policy" "target_tracking" {
  name                   = "${var.environment}-${var.region}-medusa-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.app.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}

# TLS Key pour SSH
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# AWS Key Pair
resource "aws_key_pair" "generated_key" {
  key_name   = "key-${var.environment}-${var.region}-asg"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Sauvegarder la clé SSH
resource "local_file" "ssh_private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.root}/keys/${var.environment}-${var.region}-asg-key.pem"
  file_permission = "0400"
}
