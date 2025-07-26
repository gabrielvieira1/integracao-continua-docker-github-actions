#!/bin/bash

# Script para criar infraestrutura EC2 usando Terraform
# Baseado nos scripts shell originais mas usando Terraform

set -e

echo "🚀 Iniciando criação da infraestrutura EC2 para API Go"
echo "=================================================="

# Configurações
ENVIRONMENT="dev"
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
    echo "✅ Infraestrutura criada com sucesso!"
    echo ""
    echo "📊 Informações dos recursos criados:"
    terraform output
    
    echo ""
    echo "🔗 Para destruir a infraestrutura posteriormente, execute:"
    echo "   cd $TERRAFORM_DIR && terraform destroy"
    
else
    echo "❌ Operação cancelada pelo usuário."
    exit 1
fi

echo ""
echo "🎉 Script concluído!"
