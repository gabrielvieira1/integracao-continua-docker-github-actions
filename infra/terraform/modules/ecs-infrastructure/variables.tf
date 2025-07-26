# Configurações do projeto
variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Configurações de rede
variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs das subnets"
  type        = list(string)
}

# Security Groups existentes (reutilizar do EC2)
variable "existing_api_sg_id" {
  description = "ID do Security Group da API (reutilizar do módulo EC2)"
  type        = string
}

variable "existing_rds_sg_id" {
  description = "ID do Security Group do RDS (reutilizar do módulo EC2)"
  type        = string
}

# Configurações do banco de dados
variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
}

variable "db_username" {
  description = "Usuário do banco de dados"
  type        = string
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "Endpoint do banco de dados"
  type        = string
}

variable "db_port" {
  description = "Porta do banco de dados"
  type        = number
  default     = 5432
}

# Configurações do container
variable "docker_image" {
  description = "Imagem Docker para a aplicação"
  type        = string
}

variable "container_port" {
  description = "Porta do container da aplicação"
  type        = number
  default     = 8000
}

# Tags
variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}
