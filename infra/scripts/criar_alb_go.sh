#!/bin/bash
set -e
source ./config.sh

# As variáveis ALB_NAME e TARGET_GROUP_NAME agora vêm diretamente do config.sh
# e não precisam mais ser definidas aqui.

# --- Lógica do Script ---
echo "🔎 Gerenciando Application Load Balancer e Target Group..."

# 1. Obter a VPC e as Sub-redes
VPC_ID=$(aws ec2 describe-vpcs --region "$AWS_REGION" --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text)
SUBNET_IDS=$(aws ec2 describe-subnets --region "$AWS_REGION" --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[*].SubnetId" --output text | tr -s '\t' ' ')

# 2. Criar o Target Group
echo "  - Verificando Target Group '${TARGET_GROUP_NAME}'..."
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names "$TARGET_GROUP_NAME" --region "$AWS_REGION" --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null || true)
if [ -z "$TARGET_GROUP_ARN" ]; then
    echo "  - Criando Target Group..."
    TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
        --name "$TARGET_GROUP_NAME" \
        --protocol HTTP \
        --port 8000 \
        --vpc-id "$VPC_ID" \
        --health-check-protocol HTTP \
        --health-check-path /health \
        --health-check-port traffic-port \
        --target-type ip \
        --region "$AWS_REGION" \
        --query "TargetGroups[0].TargetGroupArn" --output text)
    echo "  - Target Group criado: ${TARGET_GROUP_ARN}"
else
    echo "  - Target Group já existe: ${TARGET_GROUP_ARN}"
fi

# 3. Criar o Application Load Balancer
echo "  - Verificando Load Balancer '${ALB_NAME}'..."
LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --region "$AWS_REGION" --query "LoadBalancers[0].LoadBalancerArn" --output text 2>/dev/null || true)
if [ -z "$LOAD_BALANCER_ARN" ]; then
    echo "  - Criando Application Load Balancer..."
    SG_API_ID=$(aws ec2 describe-security-groups --region "$AWS_REGION" --filters "Name=group-name,Values=${SG_API_NAME}" --query "SecurityGroups[0].GroupId" --output text)
    LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer \
        --name "$ALB_NAME" \
        --type application \
        --subnets $SUBNET_IDS \
        --security-groups "$SG_API_ID" \
        --region "$AWS_REGION" \
        --query "LoadBalancers[0].LoadBalancerArn" --output text)
    echo "  - Load Balancer criado: ${LOAD_BALANCER_ARN}"
else
    echo "  - Load Balancer já existe: ${LOAD_BALANCER_ARN}"
fi

# 4. Criar o Listener
echo "  - Verificando Listener na porta 80..."
LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$LOAD_BALANCER_ARN" --region "$AWS_REGION" --query "Listeners[?Port==\`80\`].ListenerArn" --output text 2>/dev/null || true)
if [ -z "$LISTENER_ARN" ]; then
    echo "  - Criando Listener..."
    aws elbv2 create-listener \
        --load-balancer-arn "$LOAD_BALANCER_ARN" \
        --protocol HTTP \
        --port 80 \
        --default-actions Type=forward,TargetGroupArn="$TARGET_GROUP_ARN" \
        --region "$AWS_REGION" > /dev/null
    echo "  - Listener criado."
else
    echo "  - Listener já existe."
fi

# Saída final: O ARN do Target Group
echo "$TARGET_GROUP_ARN"