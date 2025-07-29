#!/bin/bash

# Script MESTRE para criar TODA a infraestrutura (EC2 + RDS + ECS + ALB)
# Cria nova infraestrutura usando módulos Terraform

set -e

echo "🚀 Script de Infraestrutura: CRIAR INFRAESTRUTURA"
echo "================================================="

echo "🚀 Criando TODA a infraestrutura: EC2 + RDS + ECS + ALB"
echo "======================================================="

# Configurações
ENVIRONMENT="dev"
AWS_REGION="us-east-1"
TERRAFORM_DIR="../terraform/environments/${ENVIRONMENT}"

# Verificações
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform não está instalado."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI não está configurado."
    exit 1
fi

cd "$TERRAFORM_DIR"

echo "📁 Diretório: $(pwd)"
echo "🔧 Ambiente: $ENVIRONMENT"
echo "🌎 Região: $AWS_REGION"
echo ""

# Mostrar o que será criado
echo "📦 RECURSOS QUE SERÃO CRIADOS:"
echo "   ├── 🔒 Security Groups (API e RDS) - compartilhados"
echo "   ├── 🖥️  EC2 Instance (t2.micro)"
echo "   ├── 🗄️  RDS PostgreSQL (db.t4g.micro)"
echo "   ├── 🐳 ECS Cluster"
echo "   ├── 📋 ECS Task Definition"
echo "   ├── 🔄 ECS Service"
echo "   ├── ⚖️  Application Load Balancer"
echo "   ├── 🎯 Target Group"
echo "   └── 👤 IAM Roles"
echo ""

# Inicializar Terraform
echo "🔄 Inicializando Terraform..."
terraform init

# Validar configuração
echo "✅ Validando configuração..."
terraform validate

# Planejar mudanças
echo "📋 Planejando infraestrutura completa..."
terraform plan

echo ""
echo "💰 ESTIMATIVA DE CUSTOS (por mês):"
echo "   - EC2 t2.micro: ~$8.50"
echo "   - RDS db.t4g.micro: ~$12.00"
echo "   - ECS Fargate (1 task): ~$6.00"
echo "   - ALB: ~$16.00"
echo "   - TOTAL ESTIMADO: ~$42.50/mês"
echo ""

# Confirmação
read -p "🤔 Deseja criar TODA a infraestrutura? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Criando infraestrutura completa..."
    terraform apply -auto-approve
    
    echo ""
    echo "✅ INFRAESTRUTURA COMPLETA CRIADA COM SUCESSO!"
    echo ""
    
    # Capturar outputs importantes
    echo "📊 RECURSOS CRIADOS:"
    echo "==================="
    terraform output
    
    echo ""
    echo "🌐 URLS DE ACESSO:"
    echo "=================="
    EC2_URL=$(terraform output -raw ec2_application_url 2>/dev/null || echo "não disponível")
    ECS_ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "não disponível")
    
    # URLs corretas baseadas na configuração atual
    if [ "$EC2_URL" != "não disponível" ]; then
        echo "🖥️  EC2 Strategy: $EC2_URL"
    else
        echo "🖥️  EC2 Strategy: não disponível"
    fi
    
    if [ "$ECS_ALB_DNS" != "não disponível" ]; then
        echo "🐳 ECS Strategy: http://$ECS_ALB_DNS:8000"
    else
        echo "🐳 ECS Strategy: não disponível"
    fi
    
    echo ""
    echo "🔍 HEALTH CHECKS:"
    echo "================="
    if [ "$EC2_URL" != "não disponível" ]; then
        echo "🖥️  EC2 Health: $EC2_URL/health"
    else
        echo "🖥️  EC2 Health: não disponível"
    fi
    
    if [ "$ECS_ALB_DNS" != "não disponível" ]; then
        echo "🐳 ECS Health: http://$ECS_ALB_DNS:8000/health"
    else
        echo "🐳 ECS Health: não disponível"
    fi
    
    echo ""
    echo "📋 INFORMAÇÕES PARA GITHUB ACTIONS:"
    echo "===================================="
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "não disponível")
    SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null || echo "não disponível")
    TASK_FAMILY=$(terraform output -raw ecs_task_definition_family 2>/dev/null || echo "não disponível")
    ALB_NAME=$(terraform output -raw alb_name 2>/dev/null || echo "não disponível")
    
    echo "   - ECS_CLUSTER_NAME: $CLUSTER_NAME"
    echo "   - ECS_SERVICE_NAME: $SERVICE_NAME"
    echo "   - ECS_TASK_FAMILY: $TASK_FAMILY"
    echo "   - ALB_NAME: $ALB_NAME"
    
    echo ""
    echo "🎯 PRÓXIMOS PASSOS:"
    echo "=================="
    echo "1. ✅ Faça push no GitHub para testar os workflows"
    echo "2. ✅ Acesse as URLs acima para verificar as aplicações"
    echo "3. ✅ Compare o comportamento entre EC2 e ECS"
    echo "4. ✅ Monitore os custos no AWS Console"
    
    echo ""
    echo "🗑️  Para destruir tudo posteriormente:"
    echo "   ./destroy_unified_terraform.sh"
    
else
    echo "❌ Operação cancelada."
    exit 1
fi

echo ""
echo "🎉 INFRAESTRUTURA COMPLETA PRONTA!"