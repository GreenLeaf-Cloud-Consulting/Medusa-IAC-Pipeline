# EC2 Database Module
# Crée des instances EC2 dédiées pour PostgreSQL

# Clé SSH pour les instances DB
resource "tls_private_key" "db_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "db_key" {
  key_name   = "${var.environment}-${var.region_name}-db-key-rayane"
  public_key = tls_private_key.db_ssh_key.public_key_openssh

  tags = {
    Name        = "${var.environment}-${var.region_name}-db-key-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
  }
}

# Security Group pour les instances DB
resource "aws_security_group" "database" {
  name        = "${var.environment}-${var.region_name}-db-sg-rayane"
  description = "Security group for ${var.environment} database instances in ${var.region_name}"
  vpc_id      = var.vpc_id

  # PostgreSQL depuis les app servers
  ingress {
    description     = "PostgreSQL from App servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.app_security_group_ids
  }

  # PostgreSQL depuis les autres DB (réplication)
  ingress {
    description = "PostgreSQL replication"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
  }

  # PostgreSQL depuis les autres régions (cross-region replication)  
  dynamic "ingress" {
    for_each = length(var.peer_database_cidr_blocks) > 0 ? [1] : []
    content {
      description = "PostgreSQL from cross-region databases"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = var.peer_database_cidr_blocks
    }
  }

  # SSH pour administration (optionnel, à restreindre)
  ingress {
    description = "SSH for administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  # Outbound - tout autorisé
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-db-sg-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
  }
}

# EBS Volume pour la base de données PRIMARY
resource "aws_ebs_volume" "primary_data" {
  count = var.is_primary ? 1 : 0

  availability_zone = var.availability_zone
  size              = var.ebs_volume_size
  type              = var.ebs_volume_type
  iops              = var.ebs_volume_type == "gp3" || var.ebs_volume_type == "io1" || var.ebs_volume_type == "io2" ? var.ebs_iops : null
  throughput        = var.ebs_volume_type == "gp3" ? var.ebs_throughput : null
  encrypted         = true

  tags = {
    Name        = "${var.environment}-${var.region_name}-db-primary-data-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    Type        = "database"
  }
}

# Instance EC2 pour PostgreSQL PRIMARY
resource "aws_instance" "primary" {
  count = var.is_primary ? 1 : 0

  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.db_key.key_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids      = [aws_security_group.database.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              apt-get update
              apt-get upgrade -y

              # Install basic tools
              apt-get install -y \
                curl \
                wget \
                git \
                htop \
                vim

              # Set hostname
              hostnamectl set-hostname ${var.environment}-${var.region_name}-db-primary
              EOF

  tags = {
    Name        = "${var.environment}-${var.region_name}-db-primary-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    Role        = "database-primary"
    Region      = var.region_name
    ManagedBy   = "Terraform"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# Attacher le volume EBS à l'instance PRIMARY
resource "aws_volume_attachment" "primary_data" {
  count = var.is_primary ? 1 : 0

  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.primary_data[0].id
  instance_id = aws_instance.primary[0].id
}

# EBS Volume pour les REPLICAS
resource "aws_ebs_volume" "replica_data" {
  count = var.replica_count

  availability_zone = var.availability_zone
  size              = var.replica_ebs_volume_size
  type              = var.ebs_volume_type
  iops              = var.ebs_volume_type == "gp3" || var.ebs_volume_type == "io1" || var.ebs_volume_type == "io2" ? var.ebs_iops : null
  throughput        = var.ebs_volume_type == "gp3" ? var.ebs_throughput : null
  encrypted         = true

  tags = {
    Name        = "${var.environment}-${var.region_name}-db-replica-${count.index + 1}-data-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    Type        = "database-replica"
  }
}

# Instances EC2 pour PostgreSQL REPLICAS
resource "aws_instance" "replica" {
  count = var.replica_count

  ami           = var.ami
  instance_type = var.replica_instance_type
  key_name      = aws_key_pair.db_key.key_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids      = [aws_security_group.database.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              apt-get update
              apt-get upgrade -y

              # Install basic tools
              apt-get install -y \
                curl \
                wget \
                git \
                htop \
                vim

              # Set hostname
              hostnamectl set-hostname ${var.environment}-${var.region_name}-db-replica-${count.index + 1}
              EOF

  tags = {
    Name        = "${var.environment}-${var.region_name}-db-replica-${count.index + 1}-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    Role        = "database-replica"
    Region      = var.region_name
    ManagedBy   = "Terraform"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# Attacher les volumes EBS aux instances REPLICAS
resource "aws_volume_attachment" "replica_data" {
  count = var.replica_count

  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.replica_data[count.index].id
  instance_id = aws_instance.replica[count.index].id
}

# Elastic IP pour l'instance PRIMARY (optionnel mais recommandé)
resource "aws_eip" "primary" {
  count = var.is_primary && var.allocate_eip ? 1 : 0

  domain   = "vpc"
  instance = aws_instance.primary[0].id

  tags = {
    Name        = "${var.environment}-${var.region_name}-db-primary-eip-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
  }
}

# Sauvegarder la clé SSH privée
resource "local_file" "db_ssh_private_key" {
  content         = tls_private_key.db_ssh_key.private_key_pem
  filename        = "${path.root}/keys/${var.environment}-${var.region_name}-db-key.pem"
  file_permission = "0400"
}
