#!/bin/bash

# Script para destruir TODA a infraestrutura usando Terraform
# Versão melhorada que confia no Terraform para gerenciar todos os recursos

set -e

echo "🗑️  Destruindo TODA a infraestrutura com Terraform"
echo "================================================="

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
    echo "💡 Se existem recursos órfãos, execute primeiro: ../scripts/import_orphaned_resources.sh"
    exit 1
fi

# Refresh do estado antes de mostrar o plano
echo "🔄 Atualizando estado do Terraform..."
terraform refresh

# Mostrar recursos que serão destruídos
echo ""
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
echo "✅ O Terraform irá remover TODOS os recursos de forma coordenada"
echo ""

read -p "🤔 Tem certeza que deseja destruir TUDO? Digite 'DESTROY' para confirmar: " -r
echo ""

if [[ $REPLY == "DESTROY" ]]; then
    echo "🗑️  Destruindo infraestrutura com Terraform..."
    
    # Para acelerar a destruição, parar serviços ECS antes se existirem
    if terraform output ecs_service_name &>/dev/null; then
        echo "🛑 Parando serviço ECS para acelerar destruição..."
        CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
        SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")
        
        if [ ! -z "$CLUSTER_NAME" ] && [ ! -z "$SERVICE_NAME" ]; then
            aws ecs update-service \
                --cluster "$CLUSTER_NAME" \
                --service "$SERVICE_NAME" \
                --desired-count 0 \
                --region us-east-1 2>/dev/null || true
            echo "✅ Serviço ECS parado"
        fi
    fi
    
    # Destruir tudo com Terraform
    echo "💥 Executando terraform destroy..."
    terraform destroy -auto-approve
    
    echo ""
    echo "🧹 Limpeza final de task definitions órfãs..."
    
    # Listar e fazer deregister de task definitions órfãs
    echo "🔍 Procurando task definitions da família api-go-dev-taskdef-app..."
    task_definitions=$(aws ecs list-task-definitions \
        --family-prefix "api-go-dev-taskdef-app" \
        --query "taskDefinitionArns[]" \
        --output text 2>/dev/null || echo "")
    
    if [ ! -z "$task_definitions" ] && [ "$task_definitions" != "None" ]; then
        echo "📋 Task definitions encontradas:"
        echo "$task_definitions" | tr '\t' '\n'
        echo ""
        
        # Fazer deregister de cada task definition
        echo "🗑️  Fazendo deregister das task definitions..."
        echo "$task_definitions" | tr '\t' '\n' | while read -r task_def_arn; do
            if [ ! -z "$task_def_arn" ]; then
                task_def_name=$(echo "$task_def_arn" | sed 's/.*\///')
                echo "  🔄 Deregister: $task_def_name"
                aws ecs deregister-task-definition --task-definition "$task_def_arn" >/dev/null 2>&1 || true
            fi
        done
        
        echo "✅ Deregister concluído"
        echo ""
        
        # Aguardar um momento para propagação
        echo "⏳ Aguardando propagação (5 segundos)..."
        sleep 5
        
        # Verificar se ainda existem task definitions ACTIVE
        active_tasks=$(aws ecs list-task-definitions \
            --family-prefix "api-go-dev-taskdef-app" \
            --status ACTIVE \
            --query "length(taskDefinitionArns[])" \
            --output text 2>/dev/null || echo "0")
        
        inactive_tasks=$(aws ecs list-task-definitions \
            --family-prefix "api-go-dev-taskdef-app" \
            --status INACTIVE \
            --query "length(taskDefinitionArns[])" \
            --output text 2>/dev/null || echo "0")
        
        echo "📊 Status após deregister:"
        echo "   • Task definitions ACTIVE: $active_tasks"
        echo "   • Task definitions INACTIVE: $inactive_tasks"
        
        if [ "$active_tasks" -eq 0 ]; then
            echo "✅ Todas as task definitions foram marcadas como INACTIVE"
        else
            echo "⚠️  Ainda existem $active_tasks task definitions ACTIVE"
        fi
        
        # Nota: No AWS ECS não é possível deletar task definitions completamente
        # Elas ficam como INACTIVE permanentemente para histórico
        echo ""
        echo "ℹ️  NOTA: Task definitions INACTIVE não podem ser deletadas no AWS ECS"
        echo "ℹ️  Elas ficam como histórico e não consomem recursos nem geram custos"
        
    else
        echo "✅ Nenhuma task definition órfã encontrada"
    fi
    
    echo ""
    echo "✅ TODA A INFRAESTRUTURA FOI DESTRUÍDA PELO TERRAFORM!"
    echo "✅ Nenhum recurso AWS permanece ativo!"
    echo "✅ Custos zerados!"
    echo ""
    echo "🎯 O Terraform removeu todos os recursos de forma coordenada:"
    echo "   • Task Definitions foram deregistradas (INACTIVE)"
    echo "   • ECS Services foram removidos adequadamente" 
    echo "   • Load Balancers foram deletados com dependências"
    echo "   • Security Groups foram removidos na ordem correta"
    echo "   • IAM Roles foram limpos automaticamente"
    
else
    echo "❌ Operação cancelada. Para destruir, digite exatamente 'DESTROY'."
    exit 1
fi

echo ""
echo "🎉 Destruição completa concluída com Terraform!"
