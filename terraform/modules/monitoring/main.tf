# ==========================================
# MONITORING MODULE - Prometheus + Grafana
# ==========================================

# ==================== SSH KEY ====================

resource "tls_private_key" "monitoring_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "monitoring_key" {
  key_name   = "key-${var.environment}-${var.aws_region}-monitoring-rayane"
  public_key = tls_private_key.monitoring_key.public_key_openssh
}

resource "local_file" "monitoring_ssh_key" {
  content         = tls_private_key.monitoring_key.private_key_pem
  filename        = "${path.root}/keys/${var.environment}-${var.aws_region}-monitoring-key.pem"
  file_permission = "0400"
}

# ==================== SECURITY GROUP ====================

resource "aws_security_group" "monitoring" {
  name_prefix = "${var.environment}-${var.region_name}-monitoring-sg-rayane-"
  description = "Allow Grafana, Prometheus, and SSH for monitoring server"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  # Grafana UI
  ingress {
    description = "Grafana web UI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.grafana_cidr_blocks
  }

  # Prometheus UI
  ingress {
    description = "Prometheus web UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.prometheus_cidr_blocks
  }

  # All outbound (Docker pulls, apt, scraping node_exporter)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-monitoring-sg-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

# ==================== NODE EXPORTER INGRESS ====================
# Allow the monitoring server to scrape node_exporter on app/db instances

resource "aws_security_group_rule" "allow_node_exporter" {
  count = length(var.app_security_group_ids)

  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.monitoring.id
  security_group_id        = var.app_security_group_ids[count.index]
  description              = "node_exporter metrics from monitoring server"
}

# ==================== MONITORING INSTANCE ====================

resource "aws_instance" "monitoring" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  key_name                    = aws_key_pair.monitoring_key.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/scripts/install_monitoring.sh", {
    monitored_instances    = var.monitored_instances
    grafana_admin_password = var.grafana_admin_password
  })

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-monitoring-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
    Role        = "monitoring"
  }
}
