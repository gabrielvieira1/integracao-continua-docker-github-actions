# ☁️ AWS Deployment Strategies Guide

## 🎯 Visão Geral

Este projeto implementa **três estratégias de deploy** diferentes na AWS, cada uma adequada para diferentes cenários e necessidades:

- **🖥️ EC2**: Para aplicações que precisam de controle total e deploy direto de binários
- **🐳 ECS**: Para containerização gerenciada sem complexidade do Kubernetes  
- **☸️ EKS**: Para aplicações que precisam de orquestração avançada e cloud-native

Toda a infraestrutura é gerenciada via **Terraform** com módulos reutilizáveis e ambientes separados.

## ☸️ Amazon EKS Deployment

### 🚀 **Características**
- **Orquestração**: Kubernetes totalmente gerenciado
- **Escalabilidade**: Auto-scaling automático
- **Complexidade**: Alta (requer conhecimento K8s)
- **Custo**: Alto (cluster + worker nodes)

### 🔄 **Fluxo de Deploy**

```yaml
# Exemplo de uso no workflow principal
jobs:
  kubernetes-deploy:
    uses: ./.github/workflows/EKS.yml
    secrets: inherit
    if: github.ref == 'refs/heads/main'
```

### 🛠️ **Configuração Detalhada**

```mermaid
sequenceDiagram
    participant GHA as GitHub Actions
    participant AWS as AWS EKS
    participant TF as Terraform
    participant K8S as Kubernetes

    GHA->>AWS: Configure credentials
    GHA->>TF: Clone infra repository
    TF->>AWS: Provision EKS cluster
    GHA->>K8S: Update kubeconfig
    GHA->>K8S: Create secrets
    GHA->>K8S: Deploy application
    K8S->>AWS: Rolling update
```

### 📋 **Secrets Necessários**
```bash
# AWS Credentials
ID_CHAVE_ACESSO=AKIA...
CHAVE_SECRETA=...

# Database Configuration
DBHOST=database.cluster.amazonaws.com
DBUSER=postgres
DBPASSWORD=secure_password
DBNAME=production_db
DBPORT=5432
```

---

## 🐳 Amazon ECS Deployment

### 🚀 **Características**
- **Gerenciamento**: Containers sem servidor
- **Escalabilidade**: Task-based scaling
- **Complexidade**: Média (conceitos AWS)
- **Custo**: Médio (pay per task)

### 🔄 **Fluxo de Deploy**

```yaml
# Exemplo de uso no workflow principal
jobs:
  ecs-deploy:
    uses: ./.github/workflows/ECS.yml
    secrets: inherit
    if: github.ref == 'refs/heads/production'
```

### 🛠️ **Auto-Rollback Feature**

```mermaid
graph LR
    DEPLOY[🚀 Deploy New Version]
    HEALTH[❤️ Health Check]
    SUCCESS[✅ Success]
    ROLLBACK[↩️ Auto Rollback]
    
    DEPLOY --> HEALTH
    HEALTH -->|Pass| SUCCESS
    HEALTH -->|Fail| ROLLBACK
    ROLLBACK --> DEPLOY
```

### 🏗️ **Task Definition**
```json
{
  "family": "Tarefa_API-GO",
  "containerDefinitions": [
    {
      "name": "Go",
      "image": "bielvieira/go_ci:40",
      "environment": [
        {"name": "HOST", "value": "${HOST}"},
        {"name": "USER", "value": "${USER}"},
        {"name": "PASSWORD", "value": "${PASSWORD}"},
        {"name": "DBNAME", "value": "${DBNAME}"},
        {"name": "DBPORT", "value": "${DBPORT}"},
        {"name": "PORT", "value": "8000"}
      ]
    }
  ]
}
```

---

## 🖥️ Amazon EC2 Deployment

### 🚀 **Características**
- **Controle**: Acesso total ao servidor
- **Escalabilidade**: Manual ou scripted
- **Complexidade**: Baixa (conceitos básicos)
- **Custo**: Baixo (instância sempre ligada)

### 🔄 **Fluxo de Deploy**

```yaml
# Exemplo de uso no workflow principal
jobs:
  ec2-deploy:
    uses: ./.github/workflows/EC2.yml
    secrets: inherit
    needs: [build]
```

### 🛠️ **SSH Deployment Process**

```mermaid
sequenceDiagram
    participant GHA as GitHub Actions
    participant EC2 as EC2 Instance
    participant APP as Go Application

    GHA->>EC2: SSH connect
    GHA->>EC2: Transfer binary
    GHA->>EC2: Set environment vars
    GHA->>EC2: chmod +x main
    GHA->>APP: nohup ./main &
    APP->>EC2: Start on port 8000
```

### 🔑 **SSH Configuration**
```bash
# Required secrets
SSH_PRIVATE_KEY=-----BEGIN RSA PRIVATE KEY-----...
REMOTE_HOST=ec2-xx-xx-xx-xx.compute-1.amazonaws.com
REMOTE_USER=ubuntu

# Database configuration
DBHOST=your-db-host.amazonaws.com
DBUSER=postgres
DBPASSWORD=your_password
DBNAME=your_database
DBPORT=5432
```

---

## ⚡ Load Testing Strategy

### 🎯 **Objetivo**
Validar performance da aplicação em ambiente real AWS antes do deploy em produção.

### 🔄 **Workflow de Load Test**

```yaml
# Exemplo de trigger
jobs:
  load-test:
    uses: ./.github/workflows/LoadTest.yml
    secrets: inherit
    if: github.event_name == 'schedule' # Executa agendado
```

### 🏗️ **Infrastructure Lifecycle**

```mermaid
graph TD
    START[🎯 Trigger Load Test]
    DESTROY1[💥 Clean Environment]
    CREATE[🚀 Create Infrastructure]
    DEPLOY[📦 Deploy Application]
    TEST[⚡ Run Load Test]
    COLLECT[📊 Collect Metrics]
    DESTROY2[💥 Cleanup Resources]
    END[✅ Test Complete]

    START --> DESTROY1
    DESTROY1 --> CREATE
    CREATE --> DEPLOY
    DEPLOY --> TEST
    TEST --> COLLECT
    COLLECT --> DESTROY2
    DESTROY2 --> END
```

### 📊 **Locust Configuration**

```python
# Auto-generated locustfile.py
from locust import HttpUser, TaskSet, task, between

class UserTasks(TaskSet):
    @task(1)
    def index(self):
        self.client.get("/bruno")

class WebsiteUser(HttpUser):
    tasks = [UserTasks]
    wait_time = between(1, 5)
```

### 📈 **Test Parameters**
- **Users**: 10 concurrent users
- **Spawn Rate**: 5 users per second
- **Duration**: 60 seconds
- **Target**: `/bruno` endpoint
- **Environment**: Ephemeral AWS infrastructure

---

## 🎯 Escolhendo a Estratégia Certa

### 📊 **Decision Matrix**

| Critério | EKS | ECS | EC2 |
|----------|-----|-----|-----|
| **Início Rápido** | ❌ | ✅ | ✅ |
| **Escalabilidade** | ✅ | ✅ | ❌ |
| **Custo Baixo** | ❌ | ✅ | ✅ |
| **Simplicidade** | ❌ | ✅ | ✅ |
| **Flexibilidade** | ✅ | ✅ | ✅ |
| **Produção Enterprise** | ✅ | ✅ | ❌ |

### 🚀 **Recomendações**

#### 🆕 **Para Projetos Novos**
```bash
1. Desenvolvimento → EC2 (simplicidade)
2. Staging → ECS (ambiente similar à produção)
3. Produção → EKS (escalabilidade enterprise)
```

#### 🏢 **Para Empresas**
```bash
1. Proof of Concept → ECS
2. Produção Simples → ECS
3. Microserviços Complexos → EKS
```

#### 💰 **Para Startups**
```bash
1. MVP → EC2
2. Crescimento → ECS
3. Scale → EKS
```

---

## 🔧 Setup e Configuração

### 1️⃣ **Configurar Secrets no GitHub**

```bash
# AWS Credentials (Repository Level)
gh secret set AWS_ACCESS_KEY_ID_DEV --body "AKIA..."
gh secret set AWS_SECRET_ACCESS_KEY_DEV --body "..."
gh secret set AWS_ACCESS_KEY_ID_PROD --body "AKIA..."
gh secret set AWS_SECRET_ACCESS_KEY_PROD --body "..."

# Database Secrets (Environment Level)
gh secret set DB_PASSWORD_DEV --body "123456789"
gh secret set DB_PASSWORD_PROD --body "secure_password"

# Docker Registry
gh secret set USERNAME_DOCKER_HUB --body "your_username"
gh secret set PASSWORD_DOCKER_HUB --body "your_password"

# EC2 SSH (for EC2 strategy)
gh secret set SSH_PRIVATE_KEY --body "$(cat ~/.ssh/id_rsa)"
gh secret set REMOTE_USER --body "ec2-user"
```

### 2️⃣ **Provisionar Infraestrutura**

```bash
# Criar toda a infraestrutura unificada (EC2 + ECS + EKS)
cd infra/scripts/
./create_unified_terraform.sh

# OU criar módulos individuais
cd infra/terraform/environments/dev/
terraform init && terraform apply  # EC2 + RDS

cd ../ecs-dev/
terraform init && terraform apply  # ECS + ALB

cd ../prod/
terraform init && terraform apply  # EKS + Node Groups
```

### 3️⃣ **Workflow Principal Integrado**

O pipeline principal detecta qual estratégia usar baseado na branch ou commit message:

```yaml
name: Multi-Strategy AWS Deploy

on:
  push:
    branches: [main, develop]
  workflow_dispatch:
    inputs:
      deploy_strategy:
        description: 'Choose deployment strategy'
        required: true
        default: 'ec2'
        type: choice
        options:
        - ec2
        - ecs  
        - eks
        - all

jobs:
  # Pipeline principal (sempre executa)
  ci-pipeline:
    uses: ./.github/workflows/go.yml
    secrets: inherit

  # Deploy strategies (condicionais)
  deploy-ec2:
    if: |
      contains(github.event.head_commit.message, '[ec2]') ||
      github.event.inputs.deploy_strategy == 'ec2' ||
      github.event.inputs.deploy_strategy == 'all'
    uses: ./.github/workflows/EC2.yml
    needs: [ci-pipeline]
    secrets: inherit

  deploy-ecs:
    if: |
      contains(github.event.head_commit.message, '[ecs]') ||
      github.event.inputs.deploy_strategy == 'ecs' ||
      github.event.inputs.deploy_strategy == 'all'
    uses: ./.github/workflows/ECS.yml
    needs: [ci-pipeline]
    secrets: inherit

  deploy-eks:
    if: |
      contains(github.event.head_commit.message, '[eks]') ||
      github.event.inputs.deploy_strategy == 'eks' ||
      github.event.inputs.deploy_strategy == 'all'
    uses: ./.github/workflows/EKS.yml
    needs: [ci-pipeline]
    secrets: inherit

  load-test:
    if: contains(github.event.head_commit.message, '[load-test]')
    uses: ./.github/workflows/LoadTest.yml
    secrets: inherit
```

### 4️⃣ **Deploy Específico por Commit Message**

```bash
# Deploy em EC2 apenas
git commit -m "feat: nova funcionalidade [ec2]"

# Deploy em ECS apenas  
git commit -m "feat: deploy para staging [ecs]"

# Deploy em EKS para produção
git commit -m "feat: deploy para produção [eks]"

# Deploy em todas as estratégias
git commit -m "feat: deploy completo [all]"

# Executar teste de carga
git commit -m "test: validar performance [load-test]"
```

### 5️⃣ **Limpeza de Recursos**

```bash
# Destruir toda a infraestrutura
cd infra/scripts/
./destroy_unified_terraform.sh

# OU destruir módulos individuais
cd infra/terraform/environments/dev/
terraform destroy  # Remove EC2 + RDS

cd ../ecs-dev/
terraform destroy  # Remove ECS + ALB

cd ../prod/  
terraform destroy  # Remove EKS + Node Groups
```

---

## 🎯 Conclusão

Este projeto demonstra **competência completa em AWS** e **estratégias de deploy modernas**:

✅ **EC2 Direct Deploy** - Controle total com deploy SSH  
✅ **ECS Fargate** - Containerização serverless gerenciada  
✅ **EKS Kubernetes** - Orquestração cloud-native enterprise  
✅ **Load Testing** - Validação de performance automatizada  
✅ **Infrastructure as Code** - Terraform modular e reutilizável  
✅ **CI/CD Integration** - GitHub Actions com 6 workflows especializados  
✅ **Multi-Environment** - Dev, staging, production separados  
✅ **Auto-scaling** - Horizontal scaling em ECS e EKS  
✅ **Security Best Practices** - IRSA, Security Groups, Secrets Management  

**🏆 Portfolio completo demonstrando expertise DevOps/Cloud em múltiplas arquiteturas AWS!**
