#!/bin/bash
# ==================================================================
# SCRIPT DE REGRESSÃO: Desfaz a infraestrutura completa (Versão Final Otimizada)
# ==================================================================
source ./config.sh

# --- Trava de Segurança ---
echo "==================== AVISO! AÇÃO DESTRUTIVA ===================="
echo "Este script irá apagar permanentemente a infraestrutura do ambiente: '${ENVIRONMENT}'"
echo "Recursos afetados: ECS Service, Cluster, ALB, RDS (incluindo snapshots manuais), EC2, Security Groups."
echo "O BANCO DE DADOS E TODOS OS SEUS BACKUPS SERÃO PERDIDOS."
echo ""
read -p "Para confirmar, digite o nome do ambiente ('${ENVIRONMENT}'): " CONFIRMATION

if [ "$CONFIRMATION" != "$ENVIRONMENT" ]; then
    echo "Confirmação incorreta. Operação cancelada."
    exit 1
fi
echo "===================================================================="

# Higieniza as variáveis lidas do config.sh
CLEAN_ECS_SERVICE_NAME=${ECS_SERVICE_NAME%$'\r'}
CLEAN_ECS_CLUSTER_NAME=${ECS_CLUSTER_NAME%$'\r'}
CLEAN_ALB_NAME=${ALB_NAME%$'\r'}
CLEAN_TARGET_GROUP_NAME=${TARGET_GROUP_NAME%$'\r'}
CLEAN_EC2_INSTANCE_NAME=${EC2_INSTANCE_NAME%$'\r'}
CLEAN_RDS_INSTANCE_ID=${RDS_INSTANCE_ID%$'\r'}
CLEAN_DB_SUBNET_GROUP_NAME=${DB_SUBNET_GROUP_NAME%$'\r'}
CLEAN_SG_API_NAME=${SG_API_NAME%$'\r'}
CLEAN_SG_RDS_NAME=${SG_RDS_NAME%$'\r'}

# Flag para controlar a necessidade de esperar pela remoção das ENIs
NEEDS_NETWORK_WAIT=false

echo "🚀 INICIANDO A REGRESSÃO DO AMBIENTE '${ENVIRONMENT}'..."
echo "-----------------------------------------------------"

# PASSO 1: Destruir o Serviço ECS
echo "[PASSO 1/6] Removendo o Serviço ECS..."
SERVICE_EXISTS=$(aws ecs describe-services --cluster "$CLEAN_ECS_CLUSTER_NAME" --services "$CLEAN_ECS_SERVICE_NAME" --query "services[?status=='ACTIVE'].serviceName" --output text 2>/dev/null || true)
if [ -n "$SERVICE_EXISTS" ] && [ "$SERVICE_EXISTS" != "None" ]; then
    aws ecs update-service --cluster "$CLEAN_ECS_CLUSTER_NAME" --service "$CLEAN_ECS_SERVICE_NAME" --desired-count 0 --region "$AWS_REGION" > /dev/null
    echo "  - Serviço escalado para 0 tasks. Aguardando estabilização..."
    aws ecs wait services-stable --cluster "$CLEAN_ECS_CLUSTER_NAME" --services "$CLEAN_ECS_SERVICE_NAME" --region "$AWS_REGION"
    aws ecs delete-service --cluster "$CLEAN_ECS_CLUSTER_NAME" --service "$CLEAN_ECS_SERVICE_NAME" --force --region "$AWS_REGION" > /dev/null
    echo "✔️ Serviço ECS '${CLEAN_ECS_SERVICE_NAME}' removido."
    NEEDS_NETWORK_WAIT=true
else
    echo "✔️ Serviço ECS '${CLEAN_ECS_SERVICE_NAME}' já foi removido ou não existe."
fi
echo "-----------------------------------------------------"

# PASSO 2: Destruir o Application Load Balancer
echo "[PASSO 2/6] Removendo o Application Load Balancer..."
ALB_ARN=$(aws elbv2 describe-load-balancers --names "$CLEAN_ALB_NAME" --query "LoadBalancers[0].LoadBalancerArn" --output text 2>/dev/null || true)
if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then
    LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --query "Listeners[0].ListenerArn" --output text 2>/dev/null || true)
    if [ -n "$LISTENER_ARN" ]; then
        aws elbv2 delete-listener --listener-arn "$LISTENER_ARN" --region "$AWS_REGION"
        echo "  - Listener removido."
    fi
    aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region "$AWS_REGION"
    echo "  - Aguardando remoção do ALB..."
    aws elbv2 wait load-balancers-deleted --load-balancer-arns "$ALB_ARN" --region "$AWS_REGION"
    echo "✔️ ALB '${CLEAN_ALB_NAME}' removido."
    NEEDS_NETWORK_WAIT=true
else
    echo "✔️ ALB '${CLEAN_ALB_NAME}' já foi removido ou não existe."
fi
TG_ARN=$(aws elbv2 describe-target-groups --names "$CLEAN_TARGET_GROUP_NAME" --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null || true)
if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
    aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region "$AWS_REGION"
    echo "✔️ Target Group '${CLEAN_TARGET_GROUP_NAME}' removido."
else
    echo "✔️ Target Group '${CLEAN_TARGET_GROUP_NAME}' já foi removido ou não existe."
fi
echo "-----------------------------------------------------"

# PASSO 3: Destruir a Instância EC2
echo "[PASSO 3/6] Removendo a Instância EC2..."
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${CLEAN_EC2_INSTANCE_NAME}" "Name=instance-state-name,Values=running,pending,stopping,stopped" --query "Reservations[0].Instances[0].InstanceId" --output text 2>/dev/null || true)
if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --region "$AWS_REGION" > /dev/null
    echo "  - Aguardando término da instância..."
    aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"
    echo "✔️ Instância EC2 com ID '${INSTANCE_ID}' removida."
    NEEDS_NETWORK_WAIT=true
else
    echo "✔️ Instância EC2 '${CLEAN_EC2_INSTANCE_NAME}' já foi removida ou não existe."
fi
echo "-----------------------------------------------------"

# PASSO 4: Destruir a Camada de Dados (RDS)
echo "[PASSO 4/6] Removendo a Instância RDS e seus Snapshots..."
RDS_EXISTS=$(aws rds describe-db-instances --db-instance-identifier "$CLEAN_RDS_INSTANCE_ID" --query "DBInstances[0].DBInstanceIdentifier" --output text 2>/dev/null || true)
if [ -n "$RDS_EXISTS" ] && [ "$RDS_EXISTS" != "None" ]; then
    # ... (lógica para remover snapshots manuais) ...
    aws rds modify-db-instance --db-instance-identifier "$CLEAN_RDS_INSTANCE_ID" --no-deletion-protection --region "$AWS_REGION" > /dev/null
    aws rds delete-db-instance --db-instance-identifier "$CLEAN_RDS_INSTANCE_ID" --skip-final-snapshot --region "$AWS_REGION" > /dev/null
    echo "  - Aguardando remoção da instância RDS..."
    aws rds wait db-instance-deleted --db-instance-identifier "$CLEAN_RDS_INSTANCE_ID" --region "$AWS_REGION"
    echo "✔️ Instância RDS '${CLEAN_RDS_INSTANCE_ID}' removida."
    NEEDS_NETWORK_WAIT=true
else
    echo "✔️ Instância RDS '${CLEAN_RDS_INSTANCE_ID}' já foi removida ou não existe."
fi
# ... (lógica para remover o DB Subnet Group) ...
echo "-----------------------------------------------------"

# PASSO 5: Destruir o Cluster ECS
echo "[PASSO 5/6] Removendo o Cluster ECS..."
CLUSTER_EXISTS=$(aws ecs describe-clusters --clusters "$CLEAN_ECS_CLUSTER_NAME" --query "clusters[?status=='ACTIVE'].clusterName" --output text 2>/dev/null || true)
if [ -n "$CLUSTER_EXISTS" ] && [ "$CLUSTER_EXISTS" != "None" ]; then
    aws ecs delete-cluster --cluster "$CLEAN_ECS_CLUSTER_NAME" --region "$AWS_REGION" > /dev/null
    echo "✔️ Cluster ECS '${CLEAN_ECS_CLUSTER_NAME}' removido."
else
    echo "✔️ Cluster ECS '${CLEAN_ECS_CLUSTER_NAME}' já foi removido ou não existe."
fi
echo "-----------------------------------------------------"

# Espera condicional
if [ "$NEEDS_NETWORK_WAIT" = true ]; then
    echo "⏳ Aguardando 60 segundos para a AWS remover as dependências de rede (ENIs)..."
    sleep 60
else
    echo "✔️ Nenhuma remoção de recurso de rede foi necessária. Pulando o tempo de espera."
fi

# PASSO 6: Destruir a Camada de Segurança (Security Groups)
echo "[PASSO 6/6] Removendo os Security Groups..."
SG_API_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=${CLEAN_SG_API_NAME}" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || true)
SG_RDS_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=${CLEAN_SG_RDS_NAME}" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || true)

# Só tenta remover as regras se AMBOS os SGs existirem
if [ -n "$SG_API_ID" ] && [ "$SG_API_ID" != "None" ] && [ -n "$SG_RDS_ID" ] && [ "$SG_RDS_ID" != "None" ]; then
    echo "  - Removendo regras de dependência circular entre os SGs..."
    aws ec2 revoke-security-group-ingress --group-id "$SG_RDS_ID" --protocol tcp --port 5432 --source-group "$SG_API_ID" --region "$AWS_REGION" 2>/dev/null || true
    aws ec2 revoke-security-group-ingress --group-id "$SG_API_ID" --protocol -1 --port -1 --source-group "$SG_RDS_ID" --region "$AWS_REGION" 2>/dev/null || true
    echo "  - Regras de dependência removidas."
fi

# Tenta deletar os grupos individualmente
if [ -n "$SG_API_ID" ] && [ "$SG_API_ID" != "None" ]; then
    if aws ec2 delete-security-group --group-id "$SG_API_ID" --region "$AWS_REGION" 2>/dev/null; then
        echo "✔️ Security Group '${CLEAN_SG_API_NAME}' removido."
    else
        echo "⚠️ Falha ao remover o Security Group '${CLEAN_SG_API_NAME}' (ID: ${SG_API_ID}). Verifique dependências restantes."
    fi
else
    echo "✔️ Security Group '${CLEAN_SG_API_NAME}' já foi removido ou não existe."
fi

if [ -n "$SG_RDS_ID" ] && [ "$SG_RDS_ID" != "None" ]; then
    if aws ec2 delete-security-group --group-id "$SG_RDS_ID" --region "$AWS_REGION" 2>/dev/null; then
        echo "✔️ Security Group '${CLEAN_SG_RDS_NAME}' removido."
    else
        echo "⚠️ Falha ao remover o Security Group '${CLEAN_SG_RDS_NAME}' (ID: ${SG_RDS_ID}). Verifique dependências restantes."
    fi
else
    echo "✔️ Security Group '${CLEAN_SG_RDS_NAME}' já foi removido ou não existe."
fi
echo "-----------------------------------------------------"

echo "✅ SUCESSO! Regressão do ambiente '${ENVIRONMENT}' concluída."