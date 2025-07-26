#!/bin/bash

# Script para destruir infraestrutura ECS criada pelo Terraform

set -e

echo "🗑️  Destruindo infraestrutura ECS para API Go"
echo "============================================="

# Configurações
ENVIRONMENT="ecs-dev"
TERRAFORM_DIR="../terraform/environments/${ENVIRONMENT}"

# Verificar se Terraform está instalado
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform não está instalado."
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
echo ""

# Verificar se existe state file
if [ ! -f "terraform.tfstate" ]; then
    echo "⚠️  Nenhum estado Terraform encontrado. A infraestrutura pode não ter sido criada."
    exit 1
fi

# Mostrar recursos que serão destruídos
echo "📋 Recursos que serão destruídos:"
terraform plan -destroy

echo ""
echo "⚠️  ATENÇÃO: Esta operação irá DESTRUIR todos os recursos ECS!"
echo "    - ECS Cluster"
echo "    - ECS Service"
echo "    - ECS Task Definition"
echo "    - Application Load Balancer"
echo "    - Target Group"
echo "    - Security Groups"
echo "    - CloudWatch Log Groups"
echo "    - IAM Roles"
echo ""

read -p "🤔 Tem certeza que deseja destruir a infraestrutura ECS? Digite 'yes' para confirmar: " -r
echo ""

if [[ $REPLY == "yes" ]]; then
    echo "🗑️  Destruindo infraestrutura ECS..."
    
    # Primeiro, vamos verificar se há tasks em execução e pará-las
    echo "🔍 Verificando tasks ECS em execução..."
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
    SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")
    
    if [ ! -z "$CLUSTER_NAME" ] && [ ! -z "$SERVICE_NAME" ]; then
        echo "🛑 Parando serviço ECS para acelerar o destroy..."
        aws ecs update-service \
            --cluster "$CLUSTER_NAME" \
            --service "$SERVICE_NAME" \
            --desired-count 0 \
            --region us-east-1 2>/dev/null || true
            
        echo "⏳ Aguardando tasks pararem..."
        aws ecs wait services-stable \
            --cluster "$CLUSTER_NAME" \
            --services "$SERVICE_NAME" \
            --region us-east-1 2>/dev/null || true
    fi
    
    terraform destroy -auto-approve
    
    echo ""
    echo "🧹 Limpeza final de recursos órfãos..."
    
    # Verificar e remover Log Groups órfãos
    echo "🔍 Verificando CloudWatch Log Groups órfãos..."
    aws logs describe-log-groups \
        --log-group-name-prefix "/ecs/api-go-" \
        --query "logGroups[].logGroupName" \
        --output text 2>/dev/null | tr '\t' '\n' | while read -r log_group; do
        if [ ! -z "$log_group" ] && [ "$log_group" != "None" ]; then
            echo "  🗑️  Removendo Log Group órfão: $log_group"
            aws logs delete-log-group --log-group-name "$log_group" 2>/dev/null || true
        fi
    done
    
    echo ""
    echo "✅ Infraestrutura ECS destruída com sucesso!"
    
else
    echo "❌ Operação cancelada pelo usuário."
    exit 1
fi

echo ""
echo "🎉 Script concluído!"
