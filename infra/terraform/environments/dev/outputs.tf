# ========================================
# EC2 STRATEGY OUTPUTS
# ========================================
output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2_infrastructure.ec2_instance_id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2_infrastructure.ec2_public_ip
}

output "ec2_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = module.ec2_infrastructure.ec2_private_ip
}

# ========================================
# RDS OUTPUTS (compartilhado entre EC2 e ECS)
# ========================================
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.ec2_infrastructure.rds_endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.ec2_infrastructure.rds_port
}

# ========================================
# SECURITY GROUPS (compartilhados)
# ========================================
output "security_group_api_id" {
  description = "Security Group ID for API (shared by EC2 and ECS)"
  value       = module.ec2_infrastructure.security_group_api_id
}

output "security_group_rds_id" {
  description = "Security Group ID for RDS"
  value       = module.ec2_infrastructure.security_group_rds_id
}

# ========================================
# ECS STRATEGY OUTPUTS
# ========================================
output "ecs_cluster_name" {
  description = "Nome do cluster ECS"
  value       = module.ecs_infrastructure.ecs_cluster_name
}

output "ecs_service_name" {
  description = "Nome do serviço ECS"
  value       = module.ecs_infrastructure.ecs_service_name
}

output "ecs_task_definition_family" {
  description = "Família da task definition"
  value       = module.ecs_infrastructure.ecs_task_definition_family
}

output "alb_dns_name" {
  description = "DNS name do Application Load Balancer"
  value       = module.ecs_infrastructure.alb_dns_name
}

output "alb_name" {
  description = "Nome do Application Load Balancer"
  value       = module.ecs_infrastructure.alb_name
}

# ========================================
# URLS DE ACESSO
# ========================================
output "ec2_application_url" {
  description = "URL da aplicação no EC2"
  value       = "http://${module.ec2_infrastructure.ec2_public_ip}:8000"
}

output "ecs_application_url" {
  description = "URL da aplicação no ECS"
  value       = "http://${module.ecs_infrastructure.alb_dns_name}"
}

output "ec2_health_url" {
  description = "URL do health check no EC2"
  value       = "http://${module.ec2_infrastructure.ec2_public_ip}:8000/health"
}

output "ecs_health_url" {
  description = "URL do health check no ECS"
  value       = "http://${module.ecs_infrastructure.alb_dns_name}/health"
}

# ========================================
# CONNECTION DETAILS
# ========================================
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
