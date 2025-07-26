#!/bin/bash

# Script para destruir infraestrutura EC2 criada pelo Terraform

set -e

echo "🗑️  Destruindo infraestrutura EC2 para API Go"
echo "============================================="

# Configurações
ENVIRONMENT="dev"
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
echo "⚠️  ATENÇÃO: Esta operação irá DESTRUIR todos os recursos!"
echo "    - EC2 Instance"
echo "    - RDS Database (dados serão perdidos!)"
echo "    - Security Groups"
echo "    - DB Subnet Group"
echo "    - TODOS os snapshots e backups (automáticos e manuais)"
echo "    - NENHUM backup será mantido!"
echo ""

read -p "🤔 Tem certeza que deseja destruir a infraestrutura? Digite 'yes' para confirmar: " -r
echo ""

if [[ $REPLY == "yes" ]]; then
    echo "🗑️  Destruindo infraestrutura..."
    
    # Primeiro, vamos identificar os recursos RDS para limpar snapshots
    echo "🔍 Identificando recursos RDS..."
    RDS_INSTANCE_ID=$(terraform output -json 2>/dev/null | jq -r '.ec2_instance_id.value // empty' | sed 's/ec2/rds/' || echo "")
    if [ -z "$RDS_INSTANCE_ID" ]; then
        RDS_INSTANCE_ID="api-go-dev-rds-main"
    fi
    
    echo "📸 Removendo snapshots manuais do RDS..."
    # Listar e deletar snapshots manuais
    aws rds describe-db-snapshots \
        --db-instance-identifier "$RDS_INSTANCE_ID" \
        --snapshot-type manual \
        --query 'DBSnapshots[].DBSnapshotIdentifier' \
        --output text 2>/dev/null | tr '\t' '\n' | while read -r snapshot; do
        if [ ! -z "$snapshot" ] && [ "$snapshot" != "None" ]; then
            echo "  🗑️  Removendo snapshot manual: $snapshot"
            aws rds delete-db-snapshot --db-snapshot-identifier "$snapshot" 2>/dev/null || true
        fi
    done
    
    echo "🔄 Removendo backups automáticos (será feito pelo Terraform)..."
    
    terraform destroy -auto-approve
    
    echo ""
    echo "🧹 Limpeza final de recursos órfãos..."
    
    # Verificar e remover snapshots órfãos que possam ter ficado
    echo "🔍 Verificando snapshots órfãos..."
    aws rds describe-db-snapshots \
        --query "DBSnapshots[?contains(DBSnapshotIdentifier, 'api-go-dev')].DBSnapshotIdentifier" \
        --output text 2>/dev/null | tr '\t' '\n' | while read -r snapshot; do
        if [ ! -z "$snapshot" ] && [ "$snapshot" != "None" ]; then
            echo "  🗑️  Removendo snapshot órfão: $snapshot"
            aws rds delete-db-snapshot --db-snapshot-identifier "$snapshot" 2>/dev/null || true
        fi
    done
    
    # Verificar DB Subnet Groups órfãos
    echo "🔍 Verificando DB Subnet Groups órfãos..."
    aws rds describe-db-subnet-groups \
        --query "DBSubnetGroups[?contains(DBSubnetGroupName, 'api-go-dev')].DBSubnetGroupName" \
        --output text 2>/dev/null | tr '\t' '\n' | while read -r subnet_group; do
        if [ ! -z "$subnet_group" ] && [ "$subnet_group" != "None" ]; then
            echo "  🗑️  Removendo DB Subnet Group órfão: $subnet_group"
            aws rds delete-db-subnet-group --db-subnet-group-name "$subnet_group" 2>/dev/null || true
        fi
    done
    
    echo ""
    echo "✅ Infraestrutura destruída com sucesso!"
    echo "✅ Todos os snapshots e backups foram removidos!"
    
else
    echo "❌ Operação cancelada pelo usuário."
    exit 1
fi

echo ""
echo "🎉 Script concluído!"
