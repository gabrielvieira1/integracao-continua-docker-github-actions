#!/bin/bash

# Script para criar infraestrutura ECS usando Terraform
# Substitui os scripts shell por uma solução em Terraform

set -e

echo "🚀 Iniciando criação da infraestrutura ECS para API Go"
echo "=================================================="

# Configurações
ENVIRONMENT="ecs-dev"
AWS_REGION="us-east-1"
TERRAFORM_DIR="../terraform/environments/${ENVIRONMENT}"

# Verificar se Terraform está instalado
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform não está instalado. Por favor, instale o Terraform primeiro."
    echo "   Visite: https://developer.hashicorp.com/terraform/downloads"
    exit 1
fi

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI não está configurado. Execute 'aws configure' primeiro."
    exit 1
fi

# Verificar se jq está instalado
if ! command -v jq &> /dev/null; then
    echo "❌ jq não está instalado. Instale com: sudo apt-get install jq"
    exit 1
fi

# Navegar para o diretório do Terraform
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "❌ Diretório Terraform não encontrado: $TERRAFORM_DIR"
    exit 1
fi

cd "$TERRAFORM_DIR"

echo "📁 Trabalhando no diretório: $(pwd)"
echo "🔧 Ambiente: $ENVIRONMENT"
echo "🌎 Região: $AWS_REGION"
echo ""

# Verificar se existe arquivo terraform.tfvars
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 Criando arquivo terraform.tfvars de exemplo..."
    cat > terraform.tfvars << EOF
# Configurações do banco de dados
# Substitua pelos valores reais do seu RDS
db_host     = "api-go-dev-rds-main.XXXXXXX.us-east-1.rds.amazonaws.com"
db_password = "sua_senha_aqui"

# Configurações do Docker (será atualizada pelo GitHub Actions)
docker_image = "bielvieira/go_ci:latest"
EOF
    echo "⚠️  IMPORTANTE: Edite o arquivo terraform.tfvars com os valores corretos!"
    echo "   - db_host: endpoint do seu RDS"
    echo "   - db_password: senha do banco de dados"
    echo ""
    read -p "🤔 Pressione Enter quando tiver editado o terraform.tfvars..."
fi

# Inicializar Terraform
echo "🔄 Inicializando Terraform..."
terraform init

# Validar configuração
echo "✅ Validando configuração..."
terraform validate

# Planejar mudanças
echo "📋 Planejando mudanças..."
terraform plan

# Perguntar confirmação
echo ""
read -p "🤔 Deseja aplicar essas mudanças? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Aplicando mudanças..."
    terraform apply -auto-approve
    
    echo ""
    echo "✅ Infraestrutura ECS criada com sucesso!"
    echo ""
    echo "📊 Informações dos recursos criados:"
    terraform output
    
    # Obter informações importantes
    ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "não disponível")
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "não disponível")
    SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null || echo "não disponível")
    TASK_FAMILY=$(terraform output -raw ecs_task_definition_arn 2>/dev/null | cut -d'/' -f2 | cut -d':' -f1 || echo "não disponível")
    
    echo ""
    echo "🌐 URLs da aplicação:"
    echo "   - Aplicação: http://${ALB_DNS}"
    echo "   - Health Check: http://${ALB_DNS}/health"
    echo ""
    echo "📋 Informações para GitHub Actions:"
    echo "   - ECS_CLUSTER_NAME: ${CLUSTER_NAME}"
    echo "   - ECS_SERVICE_NAME: ${SERVICE_NAME}"
    echo "   - ECS_TASK_FAMILY: ${TASK_FAMILY}"
    echo "   - ALB_DNS_NAME: ${ALB_DNS}"
    echo ""
    echo "🔗 Para destruir a infraestrutura posteriormente, execute:"
    echo "   cd $TERRAFORM_DIR && terraform destroy"
    
else
    echo "❌ Operação cancelada pelo usuário."
    exit 1
fi

echo ""
echo "🎉 Script concluído!"
