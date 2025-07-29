variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

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
  default     = "ami-0e2c8caa4b6378d8c" # Amazon Linux 2023
}

# ECS Configuration
variable "docker_image" {
  description = "Docker image for the application"
  type        = string
  default     = "bielvieira/go_ci:30"
}

variable "container_port" {
  description = "Port that the container exposes"
  type        = number
  default     = 8000
}
