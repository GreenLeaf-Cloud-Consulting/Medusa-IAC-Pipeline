# France Production Environment
# Architecture complète avec ALB, 2 App instances, 1 DB Primary, 1 DB Replica

terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = "eu-west-2" # London
}

locals {
  environment = "prod"
  region_name = "france"
  ami_debian_x86  = "ami-0f0f149abf454a472" # (optionnel) Debian 12 x86_64 eu-west-2
  ami_debian_arm  = "ami-0acc7dd449f810b83" # (optionnel) Debian 12 ARM64 eu-west-2
}

# ✅ AMI Debian 12 ARM64 la plus récente (dans eu-west-2)
data "aws_ami" "debian12_arm64" {
  most_recent = true
  owners      = ["136693071363"] # Debian officiel sur AWS

  filter {
    name   = "name"
    values = ["debian-12-arm64-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==================== VPC ====================
module "vpc" {
  source = "../../../vpc"

  environment  = local.environment
  region_name  = local.region_name
  vpc_cidr     = "10.0.0.0/16"

  availability_zones = [
    "eu-west-2a",
    "eu-west-2b"
  ]

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

# ==================== ALB ====================
module "alb" {
  source = "../../../alb"

  environment             = local.environment
  region_name             = local.region_name
  vpc_id                  = module.vpc.vpc_id
  public_subnet_ids       = module.vpc.public_subnet_ids

  medusa_backend_port     = 9000
  medusa_storefront_port  = 8000

  enable_deletion_protection = false
  enable_storefront          = false
  enable_https               = false
  enable_https_redirect      = false
}

# ==================== DATABASE ====================
# Primary Database (France)
module "database_primary" {
  source = "../../../database"

  environment       = local.environment
  region_name       = local.region_name
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  availability_zone = module.vpc.availability_zones[0]
  ami               = data.aws_ami.debian12_arm64.id

  is_primary        = true
  instance_type     = "t4g.small"
  replica_count     = 0

  ebs_volume_size   = 30
  ebs_volume_type   = "gp3"
  ebs_iops          = 3000
  ebs_throughput    = 125

  allocate_eip      = true

  app_security_group_ids = [
    module.app_instance_1.security_group_id,
    module.app_instance_2.security_group_id
  ]

  # Allow cross-region replication from Germany replica (using public IP)
  peer_database_cidr_blocks = ["0.0.0.0/0"]  # À restreindre avec l'IP publique de Germany

  ssh_cidr_blocks = ["0.0.0.0/0"]
}

# Replica Database (France)
module "database_replica_france" {
  source = "../../../database"

  environment       = local.environment
  region_name       = "${local.region_name}-replica"
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[1]
  availability_zone = module.vpc.availability_zones[1]
  ami               = data.aws_ami.debian12_arm64.id

  is_primary            = false
  replica_instance_type = "t4g.small"
  replica_count         = 1

  replica_ebs_volume_size = 30
  ebs_volume_type         = "gp3"
  ebs_iops                = 3000
  ebs_throughput          = 125

  primary_ip_address = module.database_primary.primary_instance_private_ip

  app_security_group_ids = [
    module.app_instance_1.security_group_id,
    module.app_instance_2.security_group_id
  ]

  # Allow cross-region replication from Germany replica
  peer_database_cidr_blocks = []

  ssh_cidr_blocks = ["0.0.0.0/0"]
}

# ==================== APP INSTANCES ====================
# App Instance 1
module "app_instance_1" {
  source = "../../../ec2-instance"

  environment   = local.environment
  region        = "eu-west-2"
  instance_name = "app-1"
  ami           = data.aws_ami.debian12_arm64.id
  instance_type = "t4g.small"

  vpc_id                      = module.vpc.vpc_id
  subnet_id                   = module.vpc.public_subnet_ids[0]
  enable_public_ip            = true

  alb_target_group_arn        = module.alb.target_group_backend_arn
  alb_security_group_id       = module.alb.security_group_id
  database_security_group_id  = module.database_primary.security_group_id

  ssh_user      = "admin"
}

# App Instance 2
module "app_instance_2" {
  source = "../../../ec2-instance"

  environment   = local.environment
  region        = "eu-west-2"
  instance_name = "app-2"
  ami           = data.aws_ami.debian12_arm64.id
  instance_type = "t4g.small"

  vpc_id                      = module.vpc.vpc_id
  subnet_id                   = module.vpc.public_subnet_ids[1]
  enable_public_ip            = true

  alb_target_group_arn        = module.alb.target_group_backend_arn
  alb_security_group_id       = module.alb.security_group_id
  database_security_group_id  = module.database_primary.security_group_id

  ssh_user      = "admin"
}

# ===================================
# MONITORING: CloudWatch + Lambda + Discord
# ===================================

# Récupérer le secret Discord webhook
data "aws_secretsmanager_secret" "discord_webhook" {
  name = "france-prod-discord-webhook"
}

data "aws_secretsmanager_secret_version" "discord_webhook" {
  secret_id = data.aws_secretsmanager_secret.discord_webhook.id
}

# SNS Topic pour les alarmes
resource "aws_sns_topic" "cloudwatch_alarms" {
  name = "france-prod-cloudwatch-alarms"

  tags = {
    Environment = local.environment
    Purpose     = "CloudWatch alarms notifications"
  }
}

# IAM Role pour Lambda
resource "aws_iam_role" "lambda_discord_notifier" {
  name = "france-prod-lambda-discord-notifier"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Environment = local.environment
  }
}

# IAM Policy pour Lambda - Logs CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_discord_notifier.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Policy pour Lambda - Accès Secrets Manager
resource "aws_iam_role_policy" "lambda_secrets" {
  name = "lambda-secrets-access"
  role = aws_iam_role.lambda_discord_notifier.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = data.aws_secretsmanager_secret.discord_webhook.arn
    }]
  })
}

# Créer l'archive ZIP du code Lambda
data "archive_file" "lambda_discord" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function.zip"
}

# Lambda Function
resource "aws_lambda_function" "discord_notifier" {
  filename         = data.archive_file.lambda_discord.output_path
  function_name    = "france-prod-discord-notifier"
  role            = aws_iam_role.lambda_discord_notifier.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_discord.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30

  environment {
    variables = {
      DISCORD_WEBHOOK_SECRET_NAME = data.aws_secretsmanager_secret.discord_webhook.name
    }
  }

  tags = {
    Environment = local.environment
  }
}

# Permission pour SNS d'invoquer Lambda
resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cloudwatch_alarms.arn
}

# Subscription SNS → Lambda
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.cloudwatch_alarms.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.discord_notifier.arn
}

# Alarme CloudWatch - CPU > 70% pour App Instance 1
resource "aws_cloudwatch_metric_alarm" "app1_high_cpu" {
  alarm_name          = "france-prod-app1-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300  # 5 minutes
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Cette alarme se déclenche quand le CPU de App Instance 1 dépasse 70%"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    InstanceId = module.app_instance_1.instance_id
  }

  tags = {
    Environment = local.environment
  }
}

# Alarme CloudWatch - CPU > 70% pour App Instance 2
resource "aws_cloudwatch_metric_alarm" "app2_high_cpu" {
  alarm_name          = "france-prod-app2-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300  # 5 minutes
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Cette alarme se déclenche quand le CPU de App Instance 2 dépasse 70%"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    InstanceId = module.app_instance_2.instance_id
  }

  tags = {
    Environment = local.environment
  }
}

# Alarme CloudWatch - CPU > 70% pour Database Primary
resource "aws_cloudwatch_metric_alarm" "db_primary_high_cpu" {
  alarm_name          = "france-prod-db-primary-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300  # 5 minutes
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Cette alarme se déclenche quand le CPU de Database Primary dépasse 70%"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    InstanceId = module.database_primary.primary_instance_id
  }

  tags = {
    Environment = local.environment
  }
}

# Alarme CloudWatch - CPU > 70% pour Database Replica France
resource "aws_cloudwatch_metric_alarm" "db_replica_france_high_cpu" {
  alarm_name          = "france-prod-db-replica-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300  # 5 minutes
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Cette alarme se déclenche quand le CPU de Database Replica France dépasse 70%"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    InstanceId = module.database_replica_france.replica_instance_ids[0]
  }

  tags = {
    Environment = local.environment
  }
}
