# ☁️ AWS Deployment Strategies Guide

## 🎯 Visão Geral

Este projeto implementa **três estratégias de deploy** diferentes na AWS, cada uma adequada para diferentes cenários e necessidades:

- **☸️ EKS**: Para aplicações que precisam de orquestração avançada
- **🐳 ECS**: Para containerização gerenciada sem complexidade do Kubernetes
- **🖥️ EC2**: Para deploys simples e controle total da infraestrutura

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
      "image": "gabrielvieira/go_ci:latest",
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
# AWS Credentials
gh secret set ID_CHAVE_ACESSO --body "AKIA..."
gh secret set CHAVE_SECRETA --body "..."

# Database
gh secret set DBHOST --body "your-db-host"
gh secret set DBUSER --body "postgres"
gh secret set DBPASSWORD --body "secure_password"
gh secret set DBNAME --body "production_db"
gh secret set DBPORT --body "5432"

# EC2 specific
gh secret set SSH_PRIVATE_KEY --body "$(cat ~/.ssh/id_rsa)"
gh secret set REMOTE_HOST --body "ec2-xx-xx-xx-xx.compute-1.amazonaws.com"
gh secret set REMOTE_USER --body "ubuntu"
```

### 2️⃣ **Workflow Principal Integrado**

```yaml
name: AWS Multi-Strategy Deploy

on:
  push:
    branches: [main]

jobs:
  test-and-build:
    # ... job de teste e build

  # Deploy strategies
  deploy-ec2:
    if: contains(github.event.head_commit.message, '[ec2]')
    uses: ./.github/workflows/EC2.yml
    needs: [test-and-build]
    secrets: inherit

  deploy-ecs:
    if: contains(github.event.head_commit.message, '[ecs]')
    uses: ./.github/workflows/ECS.yml
    needs: [test-and-build]
    secrets: inherit

  deploy-eks:
    if: contains(github.event.head_commit.message, '[eks]')
    uses: ./.github/workflows/EKS.yml
    needs: [test-and-build]
    secrets: inherit

  load-test:
    if: contains(github.event.head_commit.message, '[load-test]')
    uses: ./.github/workflows/LoadTest.yml
    secrets: inherit
```

### 3️⃣ **Deploy com Commit Messages**

```bash
# Deploy específico por estratégia
git commit -m "feat: nova funcionalidade [ec2]"
git commit -m "feat: deploy para staging [ecs]"
git commit -m "feat: deploy para produção [eks]"
git commit -m "test: executar teste de carga [load-test]"
```

---

## 🎯 Conclusão

Este projeto demonstra **competência completa em AWS** e **estratégias de deploy modernas**:

✅ **Kubernetes (EKS)** - Orquestração enterprise  
✅ **Containers (ECS)** - Simplicidade gerenciada  
✅ **Virtual Machines (EC2)** - Controle total  
✅ **Load Testing** - Validação de performance  
✅ **Infrastructure as Code** - Terraform  
✅ **CI/CD Integration** - GitHub Actions  

**🏆 Portfolio pronto para demonstrar expertise DevOps/Cloud em qualquer entrevista!**
