#!/bin/bash

# Script para limpeza completa de recursos RDS órfãos
# Remove snapshots, backups e outros recursos que possam ter ficado

set -e

echo "🧹 Limpeza completa de recursos RDS órfãos"
echo "========================================="

PROJECT_PREFIX="api-go-dev"

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI não está configurado. Execute 'aws configure' primeiro."
    exit 1
fi

echo "🔍 Procurando recursos RDS órfãos com prefixo: $PROJECT_PREFIX"
echo ""

# 1. Remover snapshots manuais
echo "📸 Removendo snapshots manuais..."
MANUAL_SNAPSHOTS=$(aws rds describe-db-snapshots \
    --snapshot-type manual \
    --query "DBSnapshots[?contains(DBSnapshotIdentifier, '$PROJECT_PREFIX')].DBSnapshotIdentifier" \
    --output text 2>/dev/null || echo "")

if [ ! -z "$MANUAL_SNAPSHOTS" ] && [ "$MANUAL_SNAPSHOTS" != "None" ]; then
    echo "$MANUAL_SNAPSHOTS" | tr '\t' '\n' | while read -r snapshot; do
        if [ ! -z "$snapshot" ]; then
            echo "  🗑️  Removendo snapshot manual: $snapshot"
            aws rds delete-db-snapshot --db-snapshot-identifier "$snapshot" 2>/dev/null || echo "    ⚠️  Falha ao remover $snapshot"
        fi
    done
else
    echo "  ✅ Nenhum snapshot manual encontrado"
fi

# 2. Remover snapshots automáticos órfãos (normalmente são removidos automaticamente)
echo ""
echo "🔄 Verificando snapshots automáticos..."
AUTO_SNAPSHOTS=$(aws rds describe-db-snapshots \
    --snapshot-type automated \
    --query "DBSnapshots[?contains(DBSnapshotIdentifier, '$PROJECT_PREFIX')].DBSnapshotIdentifier" \
    --output text 2>/dev/null || echo "")

if [ ! -z "$AUTO_SNAPSHOTS" ] && [ "$AUTO_SNAPSHOTS" != "None" ]; then
    echo "  ⚠️  Encontrados snapshots automáticos (normalmente removidos automaticamente):"
    echo "$AUTO_SNAPSHOTS" | tr '\t' '\n' | while read -r snapshot; do
        if [ ! -z "$snapshot" ]; then
            echo "    - $snapshot"
        fi
    done
else
    echo "  ✅ Nenhum snapshot automático encontrado"
fi

# 3. Remover DB Subnet Groups órfãos
echo ""
echo "🔗 Removendo DB Subnet Groups órfãos..."
SUBNET_GROUPS=$(aws rds describe-db-subnet-groups \
    --query "DBSubnetGroups[?contains(DBSubnetGroupName, '$PROJECT_PREFIX')].DBSubnetGroupName" \
    --output text 2>/dev/null || echo "")

if [ ! -z "$SUBNET_GROUPS" ] && [ "$SUBNET_GROUPS" != "None" ]; then
    echo "$SUBNET_GROUPS" | tr '\t' '\n' | while read -r subnet_group; do
        if [ ! -z "$subnet_group" ]; then
            echo "  🗑️  Removendo DB Subnet Group: $subnet_group"
            aws rds delete-db-subnet-group --db-subnet-group-name "$subnet_group" 2>/dev/null || echo "    ⚠️  Falha ao remover $subnet_group"
        fi
    done
else
    echo "  ✅ Nenhum DB Subnet Group órfão encontrado"
fi

# 4. Verificar instâncias RDS órfãos
echo ""
echo "🖥️  Verificando instâncias RDS órfãs..."
RDS_INSTANCES=$(aws rds describe-db-instances \
    --query "DBInstances[?contains(DBInstanceIdentifier, '$PROJECT_PREFIX')].DBInstanceIdentifier" \
    --output text 2>/dev/null || echo "")

if [ ! -z "$RDS_INSTANCES" ] && [ "$RDS_INSTANCES" != "None" ]; then
    echo "  ⚠️  ATENÇÃO: Encontradas instâncias RDS que precisam ser removidas manualmente:"
    echo "$RDS_INSTANCES" | tr '\t' '\n' | while read -r instance; do
        if [ ! -z "$instance" ]; then
            echo "    - $instance"
            echo "      Para remover: aws rds delete-db-instance --db-instance-identifier $instance --skip-final-snapshot --delete-automated-backups"
        fi
    done
else
    echo "  ✅ Nenhuma instância RDS órfã encontrada"
fi

# 5. Verificar Parameter Groups personalizados
echo ""
echo "⚙️  Verificando Parameter Groups personalizados..."
PARAM_GROUPS=$(aws rds describe-db-parameter-groups \
    --query "DBParameterGroups[?contains(DBParameterGroupName, '$PROJECT_PREFIX')].DBParameterGroupName" \
    --output text 2>/dev/null || echo "")

if [ ! -z "$PARAM_GROUPS" ] && [ "$PARAM_GROUPS" != "None" ]; then
    echo "$PARAM_GROUPS" | tr '\t' '\n' | while read -r param_group; do
        if [ ! -z "$param_group" ]; then
            echo "  🗑️  Removendo Parameter Group: $param_group"
            aws rds delete-db-parameter-group --db-parameter-group-name "$param_group" 2>/dev/null || echo "    ⚠️  Falha ao remover $param_group"
        fi
    done
else
    echo "  ✅ Nenhum Parameter Group personalizado encontrado"
fi

echo ""
echo "✅ Limpeza concluída!"
echo ""
echo "💡 Dica: Para garantir que não há custos, verifique:"
echo "   - Console AWS RDS -> Snapshots"
echo "   - Console AWS RDS -> Automated backups"
echo "   - Console AWS EC2 -> Security Groups (podem ficar órfãos)"
echo ""
echo "🎉 Script concluído!"
