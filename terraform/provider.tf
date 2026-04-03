# ==========================================
# PROVIDERS TERRAFORM
# ==========================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Provider par défaut (région principale : Paris)
provider "aws" {
  region = "eu-west-3"
}

# Provider S3 global (bucket partagé en Irlande)
provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}
