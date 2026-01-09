# VPC Module
# Utilise le VPC par défaut AWS pour l'architecture Medusa

data "aws_vpc" "main" {
  default = true
}

# Internet Gateway (use default VPC's IGW)
data "aws_internet_gateway" "main" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Subnets publics (utilise les subnets par défaut)
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Subnets privés (utilise les mêmes subnets par défaut)
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Récupère les détails des subnets pour obtenir les AZs
data "aws_subnet" "default" {
  count = length(data.aws_subnets.public.ids)
  id    = data.aws_subnets.public.ids[count.index]
}

# Les route tables sont gérées automatiquement par le VPC par défaut