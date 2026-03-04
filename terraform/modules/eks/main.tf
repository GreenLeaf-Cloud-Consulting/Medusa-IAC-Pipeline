# ==========================================
# EKS MODULE - Cluster Kubernetes pour Medusa
# ==========================================

# ==================== IAM - CONTROL PLANE ====================

resource "aws_iam_role" "cluster_role" {
  name = "${var.environment}-${var.region_name}-eks-cluster-role-rayane"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.environment}-${var.region_name}-eks-cluster-role-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ==================== SECURITY GROUP - CLUSTER ====================

resource "aws_security_group" "cluster_sg" {
  name        = "${var.environment}-${var.region_name}-eks-cluster-sg-rayane"
  description = "Security group for EKS cluster ${var.environment}-${var.region_name}"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-eks-cluster-sg-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

# ==================== EKS CLUSTER ====================

resource "aws_eks_cluster" "main" {
  name     = "${var.environment}-${var.region_name}-eks-rayane"
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [aws_security_group.cluster_sg.id]
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-eks-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    Region      = var.region_name
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_resource_controller,
  ]
}

# ==================== IAM - WORKER NODES ====================

resource "aws_iam_role" "node_role" {
  name = "${var.environment}-${var.region_name}-eks-node-role-rayane"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.environment}-${var.region_name}-eks-node-role-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ==================== NODE GROUP ====================

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.environment}-${var.region_name}-eks-ng-rayane"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.subnet_ids

  instance_types = [var.node_instance_type]
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-eks-ng-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "medusa"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    Region      = var.region_name
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
  ]
}
