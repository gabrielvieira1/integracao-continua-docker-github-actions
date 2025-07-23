# Production Environment Configuration
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "go-ci-terraform-state-prod"
    key            = "eks/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "prod"
      Project     = "go-ci"
      ManagedBy   = "terraform"
      Owner       = "devops-team"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# EKS Cluster
module "eks_cluster" {
  source = "../../modules/eks-cluster"

  cluster_name       = "go-ci-prod"
  environment        = "prod"
  kubernetes_version = "1.27"

  # VPC Configuration
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets   = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  single_nat_gateway = false # Produção usa múltiplos NAT Gateways

  # Node Group Configuration
  node_instance_types = ["t3.medium", "t3.large"]
  node_min_size       = 2
  node_max_size       = 10
  node_desired_size   = 3

  # Database Configuration
  postgres_version         = "15.4"
  db_instance_class        = "db.t3.small"
  db_allocated_storage     = 100
  db_max_allocated_storage = 500
  db_name                  = var.db_name
  db_username              = var.db_username
  db_password              = var.db_password

  tags = {
    Environment = "prod"
    Project     = "go-ci"
    Terraform   = "true"
  }
}
