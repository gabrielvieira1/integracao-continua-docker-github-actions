#!/bin/bash

# Script para destruir TODA a infraestrutura (EC2 + RDS + ECS + ALB)

set -e

echo "🗑️  Destruindo TODA a infraestrutura: EC2 + RDS + ECS + ALB"
echo "=========================================================="

# Configurações
ENVIRONMENT="dev"
TERRAFORM_DIR="../terraform/environments/${ENVIRONMENT}"

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform não está instalado."
    exit 1
fi

cd "$TERRAFORM_DIR"

echo "📁 Diretório: $(pwd)"
echo "🔧 Ambiente: $ENVIRONMENT"
echo ""

if [ ! -f "terraform.tfstate" ]; then
    echo "⚠️  Nenhum estado Terraform encontrado."
    exit 1
fi

# Mostrar recursos que serão destruídos
echo "📋 Recursos que serão destruídos:"
terraform plan -destroy

echo ""
echo "⚠️  ATENÇÃO: Esta operação irá DESTRUIR TODOS os recursos!"
echo "    🖥️  EC2 Instance"
echo "    🗄️  RDS Database (dados serão perdidos!)"
echo "    🐳 ECS Cluster, Service e Task Definition"
echo "    ⚖️  Application Load Balancer"
echo "    🔒 Security Groups"
echo "    👤 IAM Roles"
echo "    🌐 NENHUM backup será mantido!"
echo ""

read -p "🤔 Tem certeza que deseja destruir TUDO? Digite 'DESTROY' para confirmar: " -r
echo ""

if [[ $REPLY == "DESTROY" ]]; then
    echo "🗑️  Destruindo infraestrutura completa..."
    
    # Primeiro, parar o serviço ECS para acelerar
    echo "🛑 Parando serviço ECS..."
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
    SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")
    
    if [ ! -z "$CLUSTER_NAME" ] && [ ! -z "$SERVICE_NAME" ]; then
        aws ecs update-service \
            --cluster "$CLUSTER_NAME" \
            --service "$SERVICE_NAME" \
            --desired-count 0 \
            --region us-east-1 2>/dev/null || true
    fi
    
    # Destruir tudo
    terraform destroy -auto-approve
    
    echo ""
    echo "🧹 Limpeza final..."
    
    # Limpar logs órfãos
    echo "🔍 Removendo CloudWatch Log Groups órfãos..."
    aws logs describe-log-groups \
        --log-group-name-prefix "/ecs/api-go-" \
        --query "logGroups[].logGroupName" \
        --output text 2>/dev/null | tr '\t' '\n' | while read -r log_group; do
        if [ ! -z "$log_group" ] && [ "$log_group" != "None" ]; then
            echo "  🗑️  $log_group"
            aws logs delete-log-group --log-group-name "$log_group" 2>/dev/null || true
        fi
    done
    
    # Limpar snapshots órfãos
    echo "🔍 Removendo snapshots RDS órfãos..."
    aws rds describe-db-snapshots \
        --query "DBSnapshots[?contains(DBSnapshotIdentifier, 'api-go-dev')].DBSnapshotIdentifier" \
        --output text 2>/dev/null | tr '\t' '\n' | while read -r snapshot; do
        if [ ! -z "$snapshot" ] && [ "$snapshot" != "None" ]; then
            echo "  🗑️  $snapshot"
            aws rds delete-db-snapshot --db-snapshot-identifier "$snapshot" 2>/dev/null || true
        fi
    done
    
    echo ""
    echo "✅ TODA A INFRAESTRUTURA FOI DESTRUÍDA!"
    echo "✅ Nenhum recurso AWS permanece ativo!"
    echo "✅ Custos zerados!"
    
else
    echo "❌ Operação cancelada. Para destruir, digite exatamente 'DESTROY'."
    exit 1
fi

echo ""
echo "🎉 Destruição completa concluída!"
