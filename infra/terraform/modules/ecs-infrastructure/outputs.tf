# ECS Cluster outputs
output "ecs_cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN do cluster ECS"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_cluster_id" {
  description = "ID do cluster ECS"
  value       = aws_ecs_cluster.main.id
}

# ECS Service outputs
output "ecs_service_name" {
  description = "Nome do serviço ECS"
  value       = aws_ecs_service.main.name
}

output "ecs_service_arn" {
  description = "ARN do serviço ECS"
  value       = aws_ecs_service.main.id
}

# ECS Task Definition outputs
output "ecs_task_definition_arn" {
  description = "ARN da task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "ecs_task_definition_family" {
  description = "Família da task definition"
  value       = aws_ecs_task_definition.main.family
}

# Load Balancer outputs
output "alb_arn" {
  description = "ARN do Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name do Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID do Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_name" {
  description = "Nome do Application Load Balancer"
  value       = aws_lb.main.name
}

# Target Group outputs
output "target_group_arn" {
  description = "ARN do Target Group"
  value       = aws_lb_target_group.main.arn
}

output "target_group_name" {
  description = "Nome do Target Group"
  value       = aws_lb_target_group.main.name
}

# Security Groups outputs (reutilizando dos existentes)
output "security_group_alb_id" {
  description = "ID do Security Group usado pelo ALB (mesmo da API)"
  value       = var.existing_api_sg_id
}

output "security_group_ecs_id" {
  description = "ID do Security Group usado pelo ECS (mesmo da API)"
  value       = var.existing_api_sg_id
}

# IAM Role output
output "ecs_task_execution_role_arn" {
  description = "ARN do IAM Role para execução de tasks"
  value       = aws_iam_role.ecs_task_execution_role.arn
}
