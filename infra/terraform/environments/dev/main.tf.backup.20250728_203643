# Development Environment Configuration for EC2 Strategy
terraform {
  required_version = ">= 1.0"

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
      Environment = "dev"
      Project     = "api-go"
      ManagedBy   = "terraform"
      Owner       = "gabriel"
    }
  }
}

# Data sources
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
  project_name = "api-go"
  environment  = "dev"
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
    Environment = "dev"
    Project     = "api-go"
    Owner       = "Gabriel"
    Strategy    = "EC2"
  }
}

# ECS Infrastructure for API Go (usando mesmos recursos)
module "ecs_infrastructure" {
  source = "../../modules/ecs-infrastructure"

  # Project Configuration
  project_name = "api-go"
  environment  = "dev"
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
    Environment = "dev"
    Project     = "api-go"
    Owner       = "Gabriel"
    Strategy    = "ECS"
  }
}
