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

  # EC2 Configuration
  instance_type = "t2.micro"
  ami_id        = "ami-0cbbe2c6a1bb2ad63" # Amazon Linux 2023
  key_name      = "API-Go-Dev"

  # Database Configuration
  db_instance_class    = "db.t4g.micro"
  db_allocated_storage = 20
  db_engine_version    = "13.21"
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password

  # Network Configuration
  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Environment = "dev"
    Project     = "api-go"
    Terraform   = "true"
  }
}
