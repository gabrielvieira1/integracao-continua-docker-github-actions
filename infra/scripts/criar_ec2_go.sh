#!/bin/bash
# Carrega todas as nossas variáveis de nomenclatura do arquivo de configuração.
source ./config.sh

# --- Configurações da Instância EC2 ---
TAG_NAME="${EC2_INSTANCE_NAME}" # Usa a variável do config.sh
AMI_ID="ami-0cbbe2c6a1bb2ad63"
INSTANCE_TYPE="t2.micro"
SUBNET_ID="subnet-047f0eb2f79b50fba"
IAM_PROFILE_ARN=""

# --- Configurações da Integração ---
SG_CREATION_SCRIPT="create_security_group_go.sh"

# --- Lógica do Script ---

# 1. Higieniza as variáveis lidas do config.sh para remover possíveis caracteres invisíveis (\r)
CLEAN_SG_API_NAME=${SG_API_NAME%$'\r'}
CLEAN_TAG_NAME=${TAG_NAME%$'\r'}

# 2. Validação e Preparação do Security Group
echo "-----------------------------------------------------"
echo "🔎 Gerenciando Security Group: ${CLEAN_SG_API_NAME}"
echo "-----------------------------------------------------"

if [ ! -f "$SG_CREATION_SCRIPT" ]; then
    echo "❌ Erro: O script '${SG_CREATION_SCRIPT}' não foi encontrado."
    exit 1
fi

FINAL_SG_ID=$(aws ec2 describe-security-groups --region "$AWS_REGION" --filters "Name=group-name,Values=${CLEAN_SG_API_NAME}" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "None")

if [ "$FINAL_SG_ID" == "None" ]; then
    echo "⚠️ Security Group '${CLEAN_SG_API_NAME}' não encontrado. Executando script de criação..."
    chmod +x "$SG_CREATION_SCRIPT"
    ./"$SG_CREATION_SCRIPT"
    FINAL_SG_ID=$(aws ec2 describe-security-groups --region "$AWS_REGION" --filters "Name=group-name,Values=${CLEAN_SG_API_NAME}" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "None")
else
    echo "✔️ Security Group '${CLEAN_SG_API_NAME}' já existe com o ID: ${FINAL_SG_ID}"
fi

if [ "$FINAL_SG_ID" == "None" ]; then
    echo "❌ Erro crítico: Não foi possível criar ou encontrar o Security Group '${CLEAN_SG_API_NAME}'."
    exit 1
fi

# 3. Validação da Instância EC2 (Idempotência)
echo "-----------------------------------------------------"
echo "🔎 Verificando se a instância EC2 '${CLEAN_TAG_NAME}' já existe..."
INSTANCE_ID=$(aws ec2 describe-instances --region "${AWS_REGION}" --filters "Name=tag:Name,Values=${CLEAN_TAG_NAME}" "Name=instance-state-name,Values=running,pending" --query "Reservations[*].Instances[*].InstanceId" --output text)
if [ -n "$INSTANCE_ID" ]; then
    echo "✔️ Uma instância ativa com o nome '${CLEAN_TAG_NAME}' (ID: ${INSTANCE_ID}) já existe."
    exit 0
fi

# 4. Criação da Instância EC2
echo "⚠️ Nenhuma instância ativa encontrada. Prosseguindo com a criação..."
echo "-----------------------------------------------------"
echo "🚀 Iniciando a criação da instância EC2 '${CLEAN_TAG_NAME}' com o SG ID: ${FINAL_SG_ID}"
echo "-----------------------------------------------------"

TAG_SPECIFICATIONS="ResourceType=instance,Tags=[{Key=Name,Value=${CLEAN_TAG_NAME}}]"
# KEY_NAME vem diretamente do config.sh
AWS_COMMAND="aws ec2 run-instances \
    --region ${AWS_REGION} \
    --image-id ${AMI_ID} \
    --instance-type ${INSTANCE_TYPE} \
    --key-name ${KEY_NAME} \
    --subnet-id ${SUBNET_ID} \
    --security-group-ids ${FINAL_SG_ID} \
    --tag-specifications '${TAG_SPECIFICATIONS}'"

if [ -n "$IAM_PROFILE_ARN" ]; then
    AWS_COMMAND+=" --iam-instance-profile Arn=${IAM_PROFILE_ARN}"
fi

# Executa o comando final
eval $AWS_COMMAND

if [ $? -eq 0 ]; then
  echo "✅ Comando de criação da instância EC2 enviado com sucesso."
else
  echo "❌ Ocorreu um erro ao tentar criar a instância EC2."
fi