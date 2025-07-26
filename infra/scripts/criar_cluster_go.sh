#!/bin/bash
set -e
# Carrega todas as nossas variáveis de nomenclatura do arquivo de configuração.
source ./config.sh

# --- Lógica do Script ---
echo "  - Verificando Cluster ECS '${ECS_CLUSTER_NAME}'..."

# Verifica se o cluster já existe usando o nome do config.sh
EXISTING_CLUSTER=$(aws ecs describe-clusters --clusters "$ECS_CLUSTER_NAME" --region "$AWS_REGION" --query "clusters[?status=='ACTIVE'].clusterName" --output text 2>/dev/null || true)

if [ -n "$EXISTING_CLUSTER" ]; then
    echo "  - Cluster ECS '${ECS_CLUSTER_NAME}' já existe."
else
    echo "  - Criando Cluster ECS '${ECS_CLUSTER_NAME}'..."
    aws ecs create-cluster --cluster-name "$ECS_CLUSTER_NAME" --region "$AWS_REGION" > /dev/null
    echo "  - Cluster criado com sucesso!"
fi