# Staging Environment Configuration
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "go-ci-terraform-state-staging"
    key            = "eks/staging/terraform.tfstate"
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
      Environment = "staging"
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

  cluster_name       = "go-ci-staging"
  environment        = "staging"
  kubernetes_version = "1.27"

  # VPC Configuration
  vpc_cidr           = "10.1.0.0/16"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets    = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets     = ["10.1.101.0/24", "10.1.102.0/24"]
  database_subnets   = ["10.1.4.0/24", "10.1.5.0/24"]
  single_nat_gateway = true # Staging usa um NAT Gateway

  # Node Group Configuration
  node_instance_types = ["t3.small"]
  node_min_size       = 1
  node_max_size       = 3
  node_desired_size   = 2

  # Database Configuration
  postgres_version         = "15.4"
  db_instance_class        = "db.t3.micro"
  db_allocated_storage     = 20
  db_max_allocated_storage = 100
  db_name                  = var.db_name
  db_username              = var.db_username
  db_password              = var.db_password

  tags = {
    Environment = "staging"
    Project     = "go-ci"
    Terraform   = "true"
  }
}
