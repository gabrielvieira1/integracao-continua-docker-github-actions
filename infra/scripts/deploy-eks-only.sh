#!/bin/bash
# Script para deploy APENAS da infraestrutura EKS

echo "🚀 Deploying ONLY EKS infrastructure..."

cd infra/terraform/environments/dev

# Clean up inconsistent lock file
echo "🧹 Cleaning up inconsistent lock file..."
rm -f .terraform.lock.hcl

# Initialize terraform with upgrade to fix version conflicts
echo "🔄 Initializing Terraform with provider upgrades..."
terraform init -upgrade

# Check if initialization was successful
if [ $? -ne 0 ]; then
    echo "❌ Terraform initialization failed!"
    exit 1
fi

# Plan apenas o módulo EKS
echo "📋 Planning EKS module only..."
terraform plan -target=module.eks_infrastructure

# Check if plan was successful
if [ $? -ne 0 ]; then
    echo "❌ Terraform plan failed!"
    exit 1
fi

# Apply apenas o módulo EKS
echo "🔨 Applying EKS module only..."
terraform apply -target=module.eks_infrastructure -auto-approve

# Check if apply was successful
if [ $? -ne 0 ]; then
    echo "❌ Terraform apply failed!"
    exit 1
fi

# Show EKS resources created
echo "✅ EKS Infrastructure deployed!"
echo "📊 EKS Resources:"
terraform show | grep -E "(eks_cluster|rds|vpc)" || echo "Use terraform show for details"

echo "🎯 Ready for EKS deployment via GitHub Actions!"
