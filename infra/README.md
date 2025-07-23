# 🏗️ Infrastructure as Code

Este diretório contém toda a infraestrutura do projeto, seguindo as melhores práticas de IaC (Infrastructure as Code).

## 📁 Estrutura

```
infra/
├── terraform/                 # Infraestrutura Terraform
│   ├── modules/               # Módulos reutilizáveis
│   │   └── eks-cluster/       # Módulo EKS + RDS
│   └── environments/          # Configurações por ambiente
│       ├── dev/               # Desenvolvimento
│       ├── staging/           # Homologação
│       └── prod/              # Produção
├── k8s/                       # Manifests Kubernetes
│   ├── base/                  # Configuração base
│   └── overlays/              # Customizações por ambiente
│       ├── dev/
│       ├── staging/
│       └── prod/
└── scripts/                   # Scripts de automação
    └── deploy.sh             # Script de deploy
```

## 🚀 Como usar

### 1. Configurar AWS
```bash
aws configure
export TF_VAR_db_password="sua-senha-segura"
```

### 2. Deploy via Script
```bash
# Deploy para staging
./infra/deploy.sh staging latest

# Deploy para produção  
./infra/deploy.sh prod v1.2.3
```

### 3. Deploy Manual

#### Terraform
```bash
cd infra/terraform/environments/prod
terraform init
terraform plan
terraform apply
```

#### Kubernetes
```bash
cd infra/k8s/overlays/prod
kustomize build . | kubectl apply -f -
```

## 🔧 Configurações por Ambiente

| Ambiente | Cluster | Nodes | Database | Recursos |
|----------|---------|--------|----------|----------|
| **Dev**      | go-ci-dev | 1-2 | db.t3.micro | Mínimo |
| **Staging**  | go-ci-staging | 1-3 | db.t3.micro | Básico |
| **Prod**     | go-ci-prod | 2-10 | db.t3.small | Alta disponibilidade |

## 🔐 Secrets Necessários

### GitHub Secrets
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
DB_PASSWORD
DB_USERNAME
DB_NAME
DOCKER_REGISTRY
```

### Kubernetes Secrets
- `database-config`: Configurações do banco
- Criados automaticamente pelo workflow

## 🏷️ Estratégia de Tags

- `main` → Produção
- `develop` → Staging  
- Feature branches → Dev (manual)

## 📊 Monitoramento

- **Logs**: CloudWatch Logs
- **Métricas**: CloudWatch + Container Insights
- **Alertas**: CloudWatch Alarms

## 🔄 Rollback

```bash
# Via kubectl
kubectl rollout undo deployment/go-api -n go-api-prod

# Via GitHub Actions (re-deploy tag anterior)
git tag v1.2.2
git push origin v1.2.2
```

## 🧹 Limpeza

```bash
# Limpar ambiente staging
cd infra/terraform/environments/staging
terraform destroy

# Limpar namespace k8s
kubectl delete namespace go-api-staging
```
