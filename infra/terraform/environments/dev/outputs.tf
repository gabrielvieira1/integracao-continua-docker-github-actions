# EC2 Outputs
output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2_infrastructure.ec2_instance_id
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2_infrastructure.ec2_public_ip
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = module.ec2_infrastructure.ec2_private_ip
}

output "ec2_application_url" {
  description = "URL to access the application on EC2"
  value       = "http://${module.ec2_infrastructure.ec2_public_ip}:8000"
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.ec2_infrastructure.rds_endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.ec2_infrastructure.rds_port
}

# Security Groups
output "security_group_api_id" {
  description = "ID of the API security group"
  value       = module.ec2_infrastructure.security_group_api_id
}

output "security_group_rds_id" {
  description = "ID of the RDS security group"
  value       = module.ec2_infrastructure.security_group_rds_id
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_infrastructure.ecs_cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_infrastructure.ecs_cluster_arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_infrastructure.ecs_service_name
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = module.ecs_infrastructure.ecs_service_arn
}

output "ecs_task_definition_family" {
  description = "Task definition family"
  value       = module.ecs_infrastructure.ecs_task_definition_family
}

# ALB Outputs
output "alb_name" {
  description = "Name of the Application Load Balancer"
  value       = module.ecs_infrastructure.alb_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.ecs_infrastructure.alb_arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ecs_infrastructure.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.ecs_infrastructure.alb_zone_id
}

output "ecs_application_url" {
  description = "URL to access the application via ECS/ALB"
  value       = "http://${module.ecs_infrastructure.alb_dns_name}:8000"
}

# Target Group Outputs
output "target_group_name" {
  description = "Name of the target group"
  value       = module.ecs_infrastructure.target_group_name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.ecs_infrastructure.target_group_arn
}

# Network
output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = data.aws_subnets.default.ids
}

# Connection Details for GitHub Actions
output "connection_details" {
  description = "Database connection details for environment variables"
  value = {
    DB_HOST_DEV     = module.ec2_infrastructure.rds_endpoint
    DB_PORT_DEV     = module.ec2_infrastructure.rds_port
    DB_USER_DEV     = var.db_username
    DB_NAME_DEV     = var.db_name
    DB_PASSWORD_DEV = var.db_password
  }
  sensitive = true
}

# URLs for Health Checks
output "ec2_health_url" {
  description = "URL do health check no EC2"
  value       = "http://${module.ec2_infrastructure.ec2_public_ip}:8000/health"
}

output "ecs_health_url" {
  description = "URL do health check no ECS"
  value       = "http://${module.ecs_infrastructure.alb_dns_name}:8000/health"
}
