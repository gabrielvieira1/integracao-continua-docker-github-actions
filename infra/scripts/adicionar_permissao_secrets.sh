#!/bin/bash
set -e
source ./config.sh

# --- Configurações ---
# O nome da role padrão que o ECS usa para executar tarefas.
EXECUTION_ROLE_NAME="ecsTaskExecutionRole"
# Nome que daremos para a nossa nova política de permissões
POLICY_NAME="ECSTaskExecutionSecretsManagerPolicy"
# ARN do segredo que a role precisa acessar. Usamos um wildcard (*) no final 
# para garantir que funcione mesmo que o segredo seja recriado.
SECRET_ARN="arn:aws:secretsmanager:${AWS_REGION}:${AWS_ACCOUNT_ID}:secret:${PROJECT_NAME}/${ENVIRONMENT}/rds-password-*"

echo "📝 Criando política de permissão para o Secrets Manager..."

# Documento da política em JSON, permitindo acesso apenas ao segredo específico
POLICY_DOCUMENT=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "${SECRET_ARN}"
        }
    ]
}
EOF
)

# Cria a política de permissão no IAM
POLICY_ARN_CREATED=$(aws iam create-policy \
    --policy-name "${POLICY_NAME}" \
    --policy-document "${POLICY_DOCUMENT}" \
    --description "Permite que a ECS Task Execution Role acesse o segredo do banco de dados." \
    --query 'Policy.Arn' --output text 2>/dev/null || true)

# Se a política já existir, busca o ARN dela
if [ -z "$POLICY_ARN_CREATED" ]; then
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    POLICY_ARN_CREATED="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
    echo "  - Política '${POLICY_NAME}' já existe."
else
    echo "  - Política '${POLICY_NAME}' criada com sucesso."
fi

echo "📎 Anexando a política à role '${EXECUTION_ROLE_NAME}'..."
aws iam attach-role-policy \
    --role-name "${EXECUTION_ROLE_NAME}" \
    --policy-arn "${POLICY_ARN_CREATED}"

echo "✅ Permissão concedida com sucesso!"