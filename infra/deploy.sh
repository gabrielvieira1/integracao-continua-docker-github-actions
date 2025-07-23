#!/bin/bash
# Deploy Infrastructure and Application to EKS

set -e

ENVIRONMENT=${1:-prod}
DOCKER_IMAGE_TAG=${2:-latest}

echo "🚀 Deploying to $ENVIRONMENT environment..."

# Terraform Apply
echo "📦 Applying Terraform configuration..."
cd infra/terraform/environments/$ENVIRONMENT
terraform init
terraform apply -auto-approve

# Get outputs
CLUSTER_NAME=$(terraform output -raw cluster_name)
DB_HOST=$(terraform output -raw db_endpoint)
DB_PORT=$(terraform output -raw db_port)

echo "✅ Infrastructure deployed!"
echo "   Cluster: $CLUSTER_NAME"
echo "   Database: $DB_HOST:$DB_PORT"

# Configure kubectl
echo "🔧 Configuring kubectl..."
aws eks update-kubeconfig --region us-east-2 --name $CLUSTER_NAME

# Create namespace
echo "📁 Creating namespace..."
kubectl apply -f ../../k8s/overlays/$ENVIRONMENT/namespace.yaml

# Create database secrets
echo "🔐 Creating database secrets..."
kubectl delete secret database-config -n go-api-$ENVIRONMENT --ignore-not-found
kubectl create secret generic database-config -n go-api-$ENVIRONMENT \
  --from-literal=host="$DB_HOST" \
  --from-literal=port="$DB_PORT" \
  --from-literal=username="$DB_USER" \
  --from-literal=password="$DB_PASSWORD" \
  --from-literal=dbname="$DB_NAME"

# Deploy application
echo "🚢 Deploying application..."
cd ../../k8s/overlays/$ENVIRONMENT

# Update image tag
kustomize edit set image go-api=*:$DOCKER_IMAGE_TAG

# Apply manifests
kubectl apply -k .

echo "✅ Deployment completed!"
echo "🌐 Getting service URL..."
kubectl get svc -n go-api-$ENVIRONMENT
