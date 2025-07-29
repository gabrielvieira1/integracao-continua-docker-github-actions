variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "api-go"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Database Configuration (valores do RDS atual)
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "root"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  default     = "123456789"
  sensitive   = true
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "AWS key pair name for EC2 access"
  type        = string
  default     = "API-Go-Dev"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-08a6efd148b1f7504" # AMI que funciona
}

# ECS Configuration
variable "docker_image" {
  description = "Docker image for the application"
  type        = string
  default     = "bielvieira/go_ci:35"
}

variable "container_port" {
  description = "Port that the container exposes"
  type        = number
  default     = 8000
}

# Network Configuration (valores descobertos)
variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "vpc-0674e4dd5302a9d90"
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
  default = [
    "subnet-045075f748999034f", # us-east-1b - Subnet que funciona (primeira)
    "subnet-047f0eb2f79b50fba", # us-east-1a
    "subnet-071855a4316fb4873", # us-east-1c
    "subnet-0135cdda8b88c08fd", # us-east-1d
    "subnet-04c15327b7ec37094", # us-east-1e
    "subnet-0812b12cfc18f7802"  # us-east-1f
  ]
}
