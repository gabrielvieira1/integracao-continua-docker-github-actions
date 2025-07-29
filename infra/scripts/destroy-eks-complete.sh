#!/bin/bash
# Script para DESTRUIR COMPLETAMENTE toda a infraestrutura EKS
# ⚠️ CUIDADO: Este script remove TUDO relacionado ao EKS

set -e  # Exit on any error

echo "🚨 ========================================"
echo "🚨 DESTRUINDO TODA INFRAESTRUTURA EKS"
echo "🚨 ========================================"
echo ""

# Função para aguardar com timeout
wait_for_completion() {
    local max_wait=$1
    local check_command=$2
    local success_message=$3
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        if eval $check_command; then
            echo "✅ $success_message"
            return 0
        fi
        echo "⏳ Aguardando... ($wait_time/$max_wait segundos)"
        sleep 10
        wait_time=$((wait_time + 10))
    done
    
    echo "⚠️ Timeout atingido, continuando..."
    return 1
}

# 1. LIMPAR APLICAÇÕES KUBERNETES
echo "🗑️ 1. Removendo aplicações Kubernetes..."
kubectl delete namespace go-api-dev --ignore-not-found=true --timeout=60s || echo "Namespace não encontrado"

# 2. DELETAR LOAD BALANCERS CRIADOS PELO K8S
echo "🗑️ 2. Removendo Load Balancers criados pelo Kubernetes..."
LB_ARNS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`) || contains(LoadBalancerName, `go-api`)].LoadBalancerArn' --output text)

if [ ! -z "$LB_ARNS" ]; then
    for LB_ARN in $LB_ARNS; do
        echo "🗑️ Deletando Load Balancer: $LB_ARN"
        aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN || echo "Erro ao deletar LB"
    done
    
    # Aguardar Load Balancers serem deletados
    wait_for_completion 300 "[ -z \"\$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, \`k8s\`) || contains(LoadBalancerName, \`go-api\`)].LoadBalancerArn' --output text)\" ]" "Load Balancers deletados"
else
    echo "✅ Nenhum Load Balancer encontrado"
fi

# 3. DELETAR TARGET GROUPS
echo "🗑️ 3. Removendo Target Groups..."
TG_ARNS=$(aws elbv2 describe-target-groups --query 'TargetGroups[?contains(TargetGroupName, `k8s`) || contains(TargetGroupName, `go-api`)].TargetGroupArn' --output text)

if [ ! -z "$TG_ARNS" ]; then
    for TG_ARN in $TG_ARNS; do
        echo "🗑️ Deletando Target Group: $TG_ARN"
        aws elbv2 delete-target-group --target-group-arn $TG_ARN || echo "Erro ao deletar TG"
    done
else
    echo "✅ Nenhum Target Group encontrado"
fi

# 4. DELETAR SECURITY GROUPS ÓRFÃOS (aguardar ENIs serem removidas)
echo "🗑️ 4. Aguardando limpeza de interfaces de rede..."
sleep 60

# 5. DESTRUIR INFRAESTRUTURA TERRAFORM EKS
echo "🗑️ 5. Destruindo infraestrutura Terraform EKS..."
cd infra/terraform/environments/dev

# Deletar apenas o módulo EKS (preservar outros recursos)
echo "🔨 Destruindo módulo EKS específico..."
terraform destroy -target=module.eks_infrastructure -auto-approve || echo "Erro no terraform destroy"

# 6. LIMPEZA DE RECURSOS ÓRFÃOS
echo "🗑️ 6. Limpeza final de recursos órfãos..."

# Security Groups órfãos relacionados ao EKS
echo "🗑️ Removendo Security Groups EKS órfãos..."
SG_IDS=$(aws ec2 describe-security-groups --query 'SecurityGroups[?contains(GroupName, `eks`) || contains(GroupName, `api-go-dev`)].GroupId' --output text)

if [ ! -z "$SG_IDS" ]; then
    for SG_ID in $SG_IDS; do
        echo "🗑️ Tentando deletar Security Group: $SG_ID"
        aws ec2 delete-security-group --group-id $SG_ID 2>/dev/null || echo "SG $SG_ID ainda em uso ou não existe"
    done
else
    echo "✅ Nenhum Security Group EKS órfão encontrado"
fi

# Network Interfaces órfãs
echo "🗑️ Removendo Network Interfaces órfãs..."
ENI_IDS=$(aws ec2 describe-network-interfaces --filters "Name=status,Values=available" --query 'NetworkInterfaces[?contains(Description, `EKS`) || contains(Description, `api-go-dev`)].NetworkInterfaceId' --output text)

if [ ! -z "$ENI_IDS" ]; then
    for ENI_ID in $ENI_IDS; do
        echo "🗑️ Deletando Network Interface: $ENI_ID"
        aws ec2 delete-network-interface --network-interface-id $ENI_ID 2>/dev/null || echo "ENI $ENI_ID não pode ser deletada"
    done
else
    echo "✅ Nenhuma Network Interface órfã encontrada"
fi

# 7. VERIFICAÇÃO FINAL
echo ""
echo "🔍 ========================================"
echo "🔍 VERIFICAÇÃO FINAL"
echo "🔍 ========================================"

echo "📊 Clusters EKS restantes:"
aws eks list-clusters --query 'clusters[?contains(@, `api-go-dev`)]' --output table || echo "Nenhum cluster EKS encontrado"

echo "📊 Load Balancers restantes:"
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`) || contains(LoadBalancerName, `go-api`)].{Name:LoadBalancerName,State:State.Code}' --output table || echo "Nenhum Load Balancer encontrado"

echo "📊 Target Groups restantes:"
aws elbv2 describe-target-groups --query 'TargetGroups[?contains(TargetGroupName, `k8s`) || contains(TargetGroupName, `go-api`)].TargetGroupName' --output table || echo "Nenhum Target Group encontrado"

echo "📊 Security Groups EKS restantes:"
aws ec2 describe-security-groups --query 'SecurityGroups[?contains(GroupName, `eks`) || contains(GroupName, `api-go-dev`)].{GroupId:GroupId,GroupName:GroupName}' --output table || echo "Nenhum Security Group EKS encontrado"

echo "📊 Network Interfaces órfãs:"
aws ec2 describe-network-interfaces --filters "Name=status,Values=available" --query 'NetworkInterfaces[?contains(Description, `EKS`) || contains(Description, `api-go-dev`)].{Id:NetworkInterfaceId,Description:Description}' --output table || echo "Nenhuma Network Interface órfã encontrada"

echo "📊 Instâncias RDS EKS:"
aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `eks`)].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}' --output table || echo "Nenhuma instância RDS EKS encontrada"

echo ""
echo "🎯 ========================================"
echo "🎯 DESTRUIÇÃO COMPLETA FINALIZADA!"
echo "🎯 ========================================"
echo ""
echo "✅ Toda infraestrutura EKS foi removida"
echo "✅ Load Balancers deletados"
echo "✅ Target Groups removidos"
echo "✅ Security Groups limpos"
echo "✅ Network Interfaces órfãs removidas"
echo "✅ Namespaces Kubernetes deletados"
echo ""
echo "⚠️  IMPORTANTE: Verifique se algum recurso ainda aparece acima"
echo "⚠️  Se sim, pode ser necessário aguardar ou deletar manualmente"
echo ""

# 8. LIMPEZA DE ARQUIVOS LOCAIS
echo "🗑️ Limpando arquivos temporários..."
rm -f iam_policy.json v2_7_2_full.yaml v2_7_2_full.yaml.bak 2>/dev/null || true

echo "🎉 SCRIPT DE DESTRUIÇÃO COMPLETO!"
