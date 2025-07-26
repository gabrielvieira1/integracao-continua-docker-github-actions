#!/bin/bash

# ==================================================================
# SCRIPT MESTRE PARA DEPLOY DA APLICAÇÃO GO NO ECS (Versão Final de 2 Etapas)
# ==================================================================
set -e
source ./config.sh

# --- Arquivos de Dependência ---
SG_CREATION_SCRIPT="create_security_group_go.sh"
ALB_CREATION_SCRIPT="criar_alb_go.sh"
CLUSTER_CREATION_SCRIPT="criar_cluster_go.sh"

TASK_DEF_JSON="task-definition.json"
SERVICE_JSON_TEMPLATE="service-definition.json"
TEMP_SERVICE_JSON="service-definition-temp.json"

trap 'rm -f $TEMP_SERVICE_JSON' EXIT

# --- INÍCIO DA EXECUÇÃO ---
if ! command -v jq &> /dev/null; then
    echo "❌ Erro: A ferramenta 'jq' é necessária mas não está instalada."
    exit 1
fi

echo "🚀 Iniciando processo de deploy da API Go no ECS..."
echo "-----------------------------------------------------"

# PASSO 1: Provisionar a Camada de Segurança
echo "PASSO 1 de 5: Provisionando a Camada de Segurança..."
chmod +x "$SG_CREATION_SCRIPT" && ./"$SG_CREATION_SCRIPT" > /dev/null
SG_API_ID=$(aws ec2 describe-security-groups --region "$AWS_REGION" --filters "Name=group-name,Values=${SG_API_NAME}" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)
if [ -z "$SG_API_ID" ]; then echo "❌ Erro: Falha ao obter o ID do SG ${SG_API_NAME}."; exit 1; fi
echo "✔️ Security Groups prontos. Usando ${SG_API_NAME} (${SG_API_ID})."
echo "-----------------------------------------------------"

# PASSO 2: Provisionar o Application Load Balancer
echo "PASSO 2 de 5: Provisionando o Application Load Balancer..."
chmod +x "$ALB_CREATION_SCRIPT"
TARGET_GROUP_ARN=$(./"$ALB_CREATION_SCRIPT")
if [ -z "$TARGET_GROUP_ARN" ]; then echo "❌ Erro: Falha ao obter o ARN do Target Group."; exit 1; fi
echo "✔️ ALB e Target Group prontos. ARN do TG: ${TARGET_GROUP_ARN}"
echo "-----------------------------------------------------"

# PASSO 3: Provisionar o Cluster ECS
echo "PASSO 3 de 5: Provisionando o Cluster ECS..."
chmod +x "$CLUSTER_CREATION_SCRIPT" && ./"$CLUSTER_CREATION_SCRIPT"
echo "✔️ Cluster ECS pronto."
echo "-----------------------------------------------------"

# PASSO 4: Registrar a Task Definition
echo "PASSO 4 de 5: Registrando a Task Definition '${ECS_TASK_FAMILY}'..."
TASK_DEF_ARN=$(aws ecs register-task-definition --cli-input-json file://${TASK_DEF_JSON} --region "$AWS_REGION" --query "taskDefinition.taskDefinitionArn" --output text)
echo "✔️ Task Definition registrada com o ARN: ${TASK_DEF_ARN}"
echo "-----------------------------------------------------"

# ==================================================================
# PASSO 5: Deploy do Serviço ECS em DUAS ETAPAS
# ==================================================================
echo "PASSO 5 de 5: Deployando o Serviço ECS '${ECS_SERVICE_NAME}' (em 2 etapas)..."
VPC_ID=$(aws ec2 describe-vpcs --region "$AWS_REGION" --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text)
SUBNET_IDS_JSON=$(aws ec2 describe-subnets --region "$AWS_REGION" --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[*].SubnetId" --output json)

EXISTING_SERVICE=$(aws ecs describe-services --cluster "$ECS_CLUSTER_NAME" --services "$ECS_SERVICE_NAME" --region "$AWS_REGION" --query "services[?status=='ACTIVE'].serviceName" --output text 2>/dev/null || true)

if [ -n "$EXISTING_SERVICE" ] && [ "$EXISTING_SERVICE" != "None" ]; then
    echo "  - Serviço já existe. Atualizando para usar a nova task definition e forçando novo deploy..."
    aws ecs update-service --cluster "$ECS_CLUSTER_NAME" --service "$ECS_SERVICE_NAME" --task-definition "$TASK_DEF_ARN" --force-new-deployment --region "$AWS_REGION" > /dev/null
else
    echo "  - Serviço não encontrado. Criando em duas etapas..."
    
    # Etapa A: Cria o serviço SEM o Load Balancer
    echo "    - Etapa A: Criando o serviço base..."
    jq \
      --arg sg_id "$SG_API_ID" \
      --argjson subnets "$SUBNET_IDS_JSON" \
      --arg cluster_name "$ECS_CLUSTER_NAME" \
      --arg service_name "$ECS_SERVICE_NAME" \
      --arg task_family "$TASK_DEF_ARN" \
      'del(.loadBalancers) | .cluster = $cluster_name | .serviceName = $service_name | .taskDefinition = $task_family | .networkConfiguration.awsvpcConfiguration.securityGroups = [$sg_id] | .networkConfiguration.awsvpcConfiguration.subnets = $subnets' \
      "$SERVICE_JSON_TEMPLATE" > "$TEMP_SERVICE_JSON"
    
    aws ecs create-service --cli-input-json file://"$TEMP_SERVICE_JSON" --region "$AWS_REGION" > /dev/null
    echo "    - Serviço base criado. Aguardando estabilização..."
    aws ecs wait services-stable --cluster "$ECS_CLUSTER_NAME" --services "$ECS_SERVICE_NAME" --region "$AWS_REGION"

    # Etapa B: Atualiza o serviço para ADICIONAR o Load Balancer
    echo "    - Etapa B: Anexando o Load Balancer ao serviço..."
    aws ecs update-service \
        --cluster "$ECS_CLUSTER_NAME" \
        --service "$ECS_SERVICE_NAME" \
        --load-balancers "[{\"targetGroupArn\":\"${TARGET_GROUP_ARN}\",\"containerName\":\"Go\",\"containerPort\":8000}]" \
        --region "$AWS_REGION" > /dev/null
fi

echo "-----------------------------------------------------"
echo "✅ SUCESSO! Deploy da aplicação no ECS concluído."