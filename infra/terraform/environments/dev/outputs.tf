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

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.ec2_infrastructure.rds_endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.ec2_infrastructure.rds_port
}

output "security_group_api_id" {
  description = "Security Group ID for API"
  value       = module.ec2_infrastructure.security_group_api_id
}

output "security_group_rds_id" {
  description = "Security Group ID for RDS"
  value       = module.ec2_infrastructure.security_group_rds_id
}

output "connection_details" {
  description = "Database connection details for environment variables"
  value = {
    DB_HOST_PROD     = module.ec2_infrastructure.rds_endpoint
    DB_PORT_PROD     = module.ec2_infrastructure.rds_port
    DB_USER_PROD     = var.db_username
    DB_NAME_PROD     = var.db_name
    DB_PASSWORD_PROD = var.db_password
  }
  sensitive = true
}
