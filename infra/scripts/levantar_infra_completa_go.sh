#!/bin/bash
set -e
source ./config.sh

# --- INÍCIO DA EXECUÇÃO ---
echo "🚀 INICIANDO O PROVISIONAMENTO COMPLETO DO AMBIENTE '${ENVIRONMENT}'..."
echo "====================================================="
chmod +x *.sh

# PASSO 1: Provisionar a Camada de Segurança (Security Groups)
echo "[PASSO 1 de 5] Provisionando a Camada de Segurança (Security Groups)..."
./create_security_group_go.sh
echo "-----------------------------------------------------"

# ==========================================================
# NOVO PASSO: Garante que a permissão do Secrets Manager existe
# ==========================================================
echo "[PASSO 2 de 5] Configurando Permissões do IAM para o ECS..."
./adicionar_permissao_secrets.sh
echo "-----------------------------------------------------"

# PASSO 3: Provisionar a Camada de Dados (RDS)
echo "[PASSO 3 de 5] Provisionando a Camada de Dados (RDS)..."
./create_rds_go.sh
echo "-----------------------------------------------------"

# PASSO 4: Provisionar a Instância EC2 de Apoio/Bastion
echo "[PASSO 4 de 5] Provisionando a Instância EC2 de Apoio/Bastion..."
./criar_ec2_go.sh
echo "-----------------------------------------------------"

# # PASSO 5: Provisionar a Camada de Aplicação (ECS)
# echo "[PASSO 5 de 5] Provisionando a Camada de Aplicação (ECS)..."
# ./deploy_api_go.sh
# echo "-----------------------------------------------------"

echo "✅ SUCESSO! Provisionamento completo da infraestrutura concluído."