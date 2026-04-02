# ==========================================
# EKS MODULE - Cluster Kubernetes pour Online Boutique
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
    Application = "boutique"
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
    Application = "boutique"
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
    endpoint_private_access = false
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-eks-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
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
    Application = "boutique"
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

resource "aws_iam_role_policy_attachment" "node_ssm_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ==================== IAM - CLUSTER AUTOSCALER ====================

resource "aws_iam_role_policy" "cluster_autoscaler" {
  name = "${var.environment}-${var.region_name}-cluster-autoscaler"
  role = aws_iam_role.node_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==================== SUBNET TAGS FOR EKS ====================

resource "aws_ec2_tag" "subnet_cluster_tag" {
  count       = length(var.subnet_ids)
  resource_id = var.subnet_ids[count.index]
  key         = "kubernetes.io/cluster/${aws_eks_cluster.main.name}"
  value       = "owned"

  depends_on = [aws_eks_cluster.main]
}

# ==================== SECURITY GROUP - NODES ====================

resource "aws_security_group" "node_sg" {
  name        = "${var.environment}-${var.region_name}-eks-node-sg-rayane"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow nodes to communicate with each other"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Allow control plane to reach nodes"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster_sg.id]
  }

  ingress {
    description     = "Allow control plane HTTPS to nodes"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster_sg.id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-eks-node-sg-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Allow cluster to receive from nodes
resource "aws_security_group_rule" "cluster_ingress_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster_sg.id
  source_security_group_id = aws_security_group.node_sg.id
  description              = "Allow nodes to reach the API server"
}

# ==================== NODE GROUP ====================

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.environment}-${var.region_name}-eks-ng-rayane"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.subnet_ids

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  tags = {
    Name        = "${var.environment}-${var.region_name}-eks-ng-rayane"
    Project     = "greenleaf"
    Environment = var.environment
    Application = "boutique"
    Owner       = "equipe@greenleaf.com"
    CostCenter  = "ecommerce"
    Region      = var.region_name
    ManagedBy   = "Terraform"
    "k8s.io/cluster-autoscaler/enabled"                      = "true"
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.main.name}" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
    aws_iam_role_policy_attachment.node_ssm_policy,
    aws_ec2_tag.subnet_cluster_tag,
  ]
}

# ==================== LAUNCH TEMPLATE ====================

resource "aws_launch_template" "node" {
  name_prefix = "${var.environment}-${var.region_name}-eks-node-lt-"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  vpc_security_group_ids = [
    aws_eks_cluster.main.vpc_config[0].cluster_security_group_id,
    aws_security_group.node_sg.id,
  ]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-${var.region_name}-eks-node-rayane"
      Project     = "greenleaf"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
