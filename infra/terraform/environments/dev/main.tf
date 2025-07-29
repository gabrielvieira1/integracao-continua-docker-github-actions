terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.92.0"
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
    }
  }
}

# Data sources para descobrir recursos existentes
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# EC2 Infrastructure for API Go
module "ec2_infrastructure" {
  source = "../../modules/ec2-infrastructure"

  # Project Configuration
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # Network Configuration
  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  # Database Configuration
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # Instance Configuration
  instance_type = var.instance_type
  key_name      = var.key_name
  ami_id        = var.ami_id

  # Tags
  tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = "Gabriel"
    Strategy    = "EC2"
  }
}

# ECS Infrastructure for API Go (usando mesmos recursos)
module "ecs_infrastructure" {
  source = "../../modules/ecs-infrastructure"

  # Project Configuration
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # Network Configuration  
  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  # Database Configuration (usando outputs do EC2/RDS)
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  db_host     = module.ec2_infrastructure.rds_endpoint
  db_port     = module.ec2_infrastructure.rds_port

  # Container Configuration
  docker_image   = var.docker_image
  container_port = var.container_port

  # Reutilizar Security Groups do EC2 (sem criar novos)
  existing_api_sg_id = module.ec2_infrastructure.security_group_api_id
  existing_rds_sg_id = module.ec2_infrastructure.security_group_rds_id

  # Tags
  tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = "Gabriel"
    Strategy    = "ECS"
  }
}

# EKS Infrastructure for API Go (SEPARADA - nova VPC e RDS)
module "eks_infrastructure" {
  source = "../../modules/eks-cluster"

  # Project Configuration
  cluster_name = "${var.project_name}-${var.environment}-eks"
  environment  = var.environment

  # Network Configuration (nova VPC dedicada)
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets   = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

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

# Recursos descobertos na AWS:
# VPC ID: vpc-0674e4dd5302a9d90
# Security Group API: sg-02f21b4cb4a134711 (api-go-dev-sg-app)
# Security Group RDS: sg-08bb193b6d1a9eb8c (api-go-dev-sg-db)
# EC2 Instance: i-0d93bd4cbe3f996cc
# RDS Instance: api-go-dev-rds-main
# ECS Cluster: api-go-dev-ecs-cluster
# ECS Service: api-go-dev-ecs-svc-app
# Task Definition: api-go-dev-taskdef-app
# ALB: api-go-dev-alb-app
# Target Groups: api-go-dev-tg-app
