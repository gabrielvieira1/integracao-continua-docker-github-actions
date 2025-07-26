#!/bin/bash

# Script para limpar e recriar infraestrutura ECS com configurações corretas
set -e

echo "🔄 Limpando e recriando infraestrutura ECS..."

# Detectar o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/infra/terraform/environments/dev"

# Verificar se encontramos o diretório correto
if [ ! -f "$TERRAFORM_DIR/main.tf" ]; then
    echo "❌ Não foi possível encontrar o arquivo main.tf do Terraform"
    echo "📍 Procurando em: $TERRAFORM_DIR/main.tf"
    exit 1
fi

# Navegar para o diretório do Terraform
cd "$TERRAFORM_DIR"

echo "📍 Diretório atual: $(pwd)"

# Verificar se o Terraform está inicializado
if [ ! -d ".terraform" ]; then
    echo "🔧 Inicializando Terraform..."
    terraform init
fi

echo ""
echo "🗑️  PASSO 1: Destruindo infraestrutura ECS antiga..."
echo "⚠️  Isso vai destruir apenas o módulo ECS, mantendo EC2 e RDS intactos"
echo ""

# Destruir apenas o módulo ECS
terraform destroy -target=module.ecs_infrastructure -auto-approve

echo ""
echo "🚀 PASSO 2: Recriando infraestrutura ECS com configurações atualizadas..."
echo ""

# Planejar as mudanças
echo "📋 Planejando nova infraestrutura ECS..."
terraform plan -target=module.ecs_infrastructure

# Perguntar confirmação
echo ""
read -p "🤔 Deseja aplicar essas mudanças? (y/n): " confirm

if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    echo "🚀 Criando nova infraestrutura ECS..."
    terraform apply -target=module.ecs_infrastructure -auto-approve
    
    echo ""
    echo "✅ Infraestrutura ECS recriada com sucesso!"
    echo ""
    
    # Mostrar informações importantes
    echo "📋 INFORMAÇÕES DA NOVA INFRAESTRUTURA:"
    echo ""
    
    # Cluster
    ECS_CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "api-go-dev-ecs-cluster")
    echo "🏗️  ECS Cluster: $ECS_CLUSTER"
    
    # Service
    ECS_SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null || echo "api-go-dev-ecs-svc-app")
    echo "🎯 ECS Service: $ECS_SERVICE"
    
    # ALB
    ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "Verificar no console AWS")
    echo "🌐 ALB DNS: $ALB_DNS"
    
    # Task Definition
    echo "📋 Task Definition: api-go-dev-taskdef-app"
    
    echo ""
    echo "🔧 CONFIGURAÇÕES APLICADAS:"
    echo "   ✅ Password em texto plano (sem Secrets Manager)"
    echo "   ✅ Logs desabilitados (sem CloudWatch)"
    echo "   ✅ Health check habilitado"
    echo "   ✅ Dockerfile simplificado"
    echo ""
    
    echo "📝 PRÓXIMOS PASSOS:"
    echo "1. 🧪 Teste Docker localmente: ./test_docker_locally.sh"
    echo "2. 🚀 Execute workflow GitHub Actions ECS"
    echo "3. 🔍 Verifique status: ./diagnose_ecs_issues.sh"
    echo "4. 🌐 Acesse aplicação: http://$ALB_DNS"
    
else
    echo "❌ Operação cancelada pelo usuário"
    exit 1
fi

echo ""
echo "🎉 Processo concluído!"
