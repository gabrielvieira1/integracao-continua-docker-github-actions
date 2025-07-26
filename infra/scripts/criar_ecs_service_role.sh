#!/bin/bash
set -e
source ./config.sh

# --- Configurações ---
CUSTOM_ECS_SERVICE_ROLE_NAME="api-go-dev-ecs-service-role"
POLICY_ARN="arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForLoadBalancers"

# Política de Confiança
TRUST_POLICY_DOCUMENT='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ecs.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}'

# --- Lógica ---
# Mensagens para humanos são enviadas para stderr (>&2)
echo "  - Verificando a role de serviço customizada '${CUSTOM_ECS_SERVICE_ROLE_NAME}'..." >&2
ROLE_ARN=$(aws iam get-role --role-name "${CUSTOM_ECS_SERVICE_ROLE_NAME}" --query "Role.Arn" --output text 2>/dev/null || true)

if [ -n "$ROLE_ARN" ] && [ "$ROLE_ARN" != "None" ]; then
    echo "  - Role customizada já existe: ${ROLE_ARN}" >&2
else
    echo "  - Criando a role customizada '${CUSTOM_ECS_SERVICE_ROLE_NAME}'..." >&2
    ROLE_ARN=$(aws iam create-role \
        --role-name "${CUSTOM_ECS_SERVICE_ROLE_NAME}" \
        --assume-role-policy-document "${TRUST_POLICY_DOCUMENT}" \
        --query "Role.Arn" --output text)
    
    echo "  - Anexando a política '${POLICY_ARN}'..." >&2
    aws iam attach-role-policy \
        --role-name "${CUSTOM_ECS_SERVICE_ROLE_NAME}" \
        --policy-arn "${POLICY_ARN}"
    
    echo "  - Aguardando 10 segundos para a propagação das permissões da IAM..." >&2
    sleep 10
    echo "  - Role customizada criada e configurada: ${ROLE_ARN}" >&2
fi

# A única saída para stdout é o ARN limpo, que será capturado pelo script principal.
echo "${ROLE_ARN}"