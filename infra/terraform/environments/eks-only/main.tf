terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.31.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Strategy    = "EKS-ONLY"
    }
  }
}

# EKS Infrastructure APENAS - Infraestrutura independente
module "eks_infrastructure" {
  source = "../../modules/eks-cluster"

  # Project Configuration
  cluster_name = "${var.project_name}-${var.environment}-eks-cluster"
  environment  = var.environment

  # Network Configuration (nova VPC dedicada)
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets    = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets     = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
  database_subnets   = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]

  # Database Configuration (RDS separado para EKS)
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # Tags
  tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = "Gabriel"
    Strategy    = "EKS"
  }
}

# Outputs importantes para o workflow EKS
output "eks_cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks_infrastructure.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = module.eks_infrastructure.cluster_endpoint
}

output "eks_rds_endpoint" {
  description = "Endpoint do RDS do EKS"
  value       = module.eks_infrastructure.rds_endpoint
}

output "eks_rds_instance_id" {
  description = "ID da instância RDS do EKS"
  value       = module.eks_infrastructure.rds_instance_id
}
