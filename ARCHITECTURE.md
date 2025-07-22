# 🏗️ Arquitetura e Fluxo de Deploy

## 📊 Visão Geral da Infraestrutura

```mermaid
graph TB
    subgraph "🔧 Desenvolvimento Local"
        DEV[👨‍💻 Desenvolvedor]
        LOCAL[💻 Ambiente Local]
        MAKE[🛠️ Makefile]
        DOCKER_LOCAL[🐳 Docker Local]
        DB_LOCAL[🐘 PostgreSQL Local]
    end

    subgraph "☁️ GitHub"
        REPO[📁 Repositório]
        ACTIONS[⚡ GitHub Actions]
        SECRETS[🔐 GitHub Secrets]
        ARTIFACTS[📦 Artifacts]
    end

    subgraph "🏭 CI/CD Pipeline"
        WORKFLOW_GO[🧪 Workflow Go]
        WORKFLOW_DOCKER[🐳 Workflow Docker]
        TESTS[🧪 Testes]
        BUILD[🔨 Build]
        LINT[🔍 Linting]
    end

    subgraph "🌐 Registry & Deploy"
        DOCKER_HUB[🐳 Docker Hub]
        PROD_ENV[🚀 Produção]
        MONITORING[📊 Monitoramento]
    end

    %% Fluxo de desenvolvimento
    DEV --> LOCAL
    LOCAL --> MAKE
    MAKE --> DOCKER_LOCAL
    MAKE --> DB_LOCAL
    MAKE --> TESTS

    %% Push para GitHub
    DEV --> REPO
    REPO --> ACTIONS
    SECRETS --> ACTIONS

    %% Pipeline CI/CD
    ACTIONS --> WORKFLOW_GO
    WORKFLOW_GO --> TESTS
    WORKFLOW_GO --> BUILD
    WORKFLOW_GO --> LINT
    BUILD --> ARTIFACTS
    ARTIFACTS --> WORKFLOW_DOCKER
    WORKFLOW_DOCKER --> DOCKER_HUB

    %% Deploy
    DOCKER_HUB --> PROD_ENV
    PROD_ENV --> MONITORING

    %% Styling
    classDef devClass fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef githubClass fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef cicdClass fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef deployClass fill:#fff3e0,stroke:#e65100,stroke-width:2px

    class DEV,LOCAL,MAKE,DOCKER_LOCAL,DB_LOCAL devClass
    class REPO,ACTIONS,SECRETS,ARTIFACTS githubClass
    class WORKFLOW_GO,WORKFLOW_DOCKER,TESTS,BUILD,LINT cicdClass
    class DOCKER_HUB,PROD_ENV,MONITORING deployClass
```

## 🔄 Fluxo Detalhado do Pipeline CI/CD

```mermaid
flowchart TD
    START([👨‍💻 Developer Push])
    
    subgraph "🧪 Test Job"
        CHECKOUT1[📥 Checkout Code]
        SETUP_GO[🔧 Setup Go Matrix]
        BUILD_APP[🔨 Build Go App]
        BUILD_DB[🐘 Build PostgreSQL]
        START_DB[▶️ Start Database]
        WAIT_DB[⏳ Wait DB Ready]
        RUN_TESTS[🧪 Run Tests]
    end

    subgraph "🔨 Build Job"
        CHECKOUT2[📥 Checkout Code]
        COMPILE[⚙️ Compile Binary]
        UPLOAD[📤 Upload Artifact]
    end

    subgraph "🐳 Docker Job"
        CHECKOUT3[📥 Checkout Code]
        DOWNLOAD[📥 Download Artifact]
        DOCKER_LOGIN[🔑 Docker Hub Login]
        DOCKER_BUILD[🏗️ Build Docker Image]
        DOCKER_PUSH[📤 Push to Registry]
        DEPLOY_INFO[📋 Show Deploy Info]
    end

    SUCCESS([✅ Pipeline Success])
    FAIL([❌ Pipeline Failed])

    %% Fluxo principal
    START --> CHECKOUT1
    CHECKOUT1 --> SETUP_GO
    SETUP_GO --> BUILD_APP
    BUILD_APP --> BUILD_DB
    BUILD_DB --> START_DB
    START_DB --> WAIT_DB
    WAIT_DB --> RUN_TESTS
    
    RUN_TESTS -->|✅ Tests Pass| CHECKOUT2
    RUN_TESTS -->|❌ Tests Fail| FAIL
    
    CHECKOUT2 --> COMPILE
    COMPILE --> UPLOAD
    
    UPLOAD --> CHECKOUT3
    CHECKOUT3 --> DOWNLOAD
    DOWNLOAD --> DOCKER_LOGIN
    DOCKER_LOGIN --> DOCKER_BUILD
    DOCKER_BUILD --> DOCKER_PUSH
    DOCKER_PUSH --> DEPLOY_INFO
    DEPLOY_INFO --> SUCCESS

    %% Styling
    classDef testClass fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef buildClass fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef dockerClass fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef startClass fill:#f1f8e9,stroke:#558b2f,stroke-width:3px
    classDef endClass fill:#ffebee,stroke:#c62828,stroke-width:3px

    class CHECKOUT1,SETUP_GO,BUILD_APP,BUILD_DB,START_DB,WAIT_DB,RUN_TESTS testClass
    class CHECKOUT2,COMPILE,UPLOAD buildClass
    class CHECKOUT3,DOWNLOAD,DOCKER_LOGIN,DOCKER_BUILD,DOCKER_PUSH,DEPLOY_INFO dockerClass
    class START startClass
    class SUCCESS,FAIL endClass
```

## 🏭 Infraestrutura de Containers

```mermaid
graph TB
    subgraph "🖥️ Ambiente de Desenvolvimento"
        subgraph "🐳 Docker Compose Local"
            APP_LOCAL[🚀 Go App Container<br/>Port: 8000]
            DB_LOCAL[🐘 PostgreSQL<br/>Port: 5432]
            PGADMIN_LOCAL[🔧 PgAdmin<br/>Port: 54321]
        end
        ENV_LOCAL[📄 .env file<br/>Local credentials]
    end

    subgraph "☁️ GitHub Actions Environment"
        subgraph "🧪 Test Environment"
            RUNNER[🏃‍♂️ Ubuntu Runner]
            DB_CI[🐘 PostgreSQL Container<br/>Test Database]
            GO_TEST[🧪 Go Test Process]
        end
        SECRETS_CI[🔐 GitHub Secrets<br/>CI credentials]
    end

    subgraph "🌐 Production Registry"
        DOCKER_HUB_REG[🐳 Docker Hub<br/>Image Registry]
        subgraph "📦 Image Layers"
            UBUNTU[🐧 Ubuntu Base]
            GO_BINARY[⚙️ Go Binary]
            CONFIG[⚙️ Runtime Config]
        end
    end

    subgraph "🚀 Production Environment"
        PROD_CONTAINER[🐳 Production Container<br/>Your Go App]
        PROD_DB[🐘 Production Database<br/>PostgreSQL]
        LOAD_BALANCER[⚖️ Load Balancer<br/>Optional]
    end

    %% Connections Development
    ENV_LOCAL --> APP_LOCAL
    ENV_LOCAL --> DB_LOCAL
    APP_LOCAL --> DB_LOCAL
    DB_LOCAL --> PGADMIN_LOCAL

    %% Connections CI
    SECRETS_CI --> RUNNER
    RUNNER --> DB_CI
    RUNNER --> GO_TEST
    GO_TEST --> DB_CI

    %% Registry
    RUNNER --> DOCKER_HUB_REG
    UBUNTU --> DOCKER_HUB_REG
    GO_BINARY --> DOCKER_HUB_REG
    CONFIG --> DOCKER_HUB_REG

    %% Production
    DOCKER_HUB_REG --> PROD_CONTAINER
    PROD_CONTAINER --> PROD_DB
    LOAD_BALANCER --> PROD_CONTAINER

    %% Styling
    classDef localClass fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef ciClass fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef registryClass fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef prodClass fill:#ffebee,stroke:#c62828,stroke-width:2px

    class APP_LOCAL,DB_LOCAL,PGADMIN_LOCAL,ENV_LOCAL localClass
    class RUNNER,DB_CI,GO_TEST,SECRETS_CI ciClass
    class DOCKER_HUB_REG,UBUNTU,GO_BINARY,CONFIG registryClass
    class PROD_CONTAINER,PROD_DB,LOAD_BALANCER prodClass
```

## 🔐 Fluxo de Segurança e Secrets

```mermaid
sequenceDiagram
    participant Dev as 👨‍💻 Developer
    participant Local as 💻 Local Env
    participant GitHub as 📁 GitHub Repo
    participant Actions as ⚡ GitHub Actions
    participant Secrets as 🔐 GitHub Secrets
    participant DockerHub as 🐳 Docker Hub
    participant Prod as 🚀 Production

    Dev->>Local: 1. Desenvolve localmente
    Local->>Local: 2. Usa .env local
    Dev->>GitHub: 3. git push
    GitHub->>Actions: 4. Trigger workflow
    Actions->>Secrets: 5. Fetch secrets
    Note over Secrets: DB_USER, DB_PASSWORD, DB_NAME<br/>USERNAME_DOCKER_HUB, PASSWORD_DOCKER_HUB
    Actions->>Actions: 6. Run tests with secrets
    Actions->>DockerHub: 7. Build & push image
    DockerHub->>Prod: 8. Deploy with runtime envs
    Note over Prod: Variables passed at runtime<br/>No secrets in image
```

## 📊 Matriz de Ambientes

| Ambiente | Database | Secrets Source | Image Source | Monitoramento |
|----------|----------|----------------|--------------|---------------|
| 🖥️ **Local** | Docker Compose | `.env` file | Local build | Logs locais |
| 🧪 **CI/CD** | GitHub Actions | GitHub Secrets | Temporary build | GitHub Actions logs |
| 🚀 **Production** | External DB | Runtime vars | Docker Hub | APM/Logs externos |

## 🔄 Estratégias de Deploy

### 🚀 AWS Deployment Strategies

```mermaid
graph TB
    IMAGE[🐳 Docker Image<br/>gabrielvieira/go_ci]
    
    subgraph "☁️ AWS Deploy Options"
        EKS[☸️ Amazon EKS<br/>Kubernetes Cluster]
        ECS[🐳 Amazon ECS<br/>Container Service]
        EC2[🖥️ Amazon EC2<br/>Virtual Machines]
    end

    subgraph "🏗️ Infrastructure Management"
        TERRAFORM[🏗️ Terraform<br/>Infrastructure as Code]
        K8S_MANIFEST[📄 Kubernetes Manifests<br/>go.yaml]
        ECS_TASK[📋 ECS Task Definition<br/>Container Config]
        SSH_DEPLOY[🔑 SSH Deployment<br/>Direct Binary]
    end

    subgraph "🧪 Testing & Validation"
        LOAD_TEST[⚡ Load Testing<br/>Locust Framework]
        HEALTH_CHECK[❤️ Health Checks<br/>Application Endpoint]
        AUTO_ROLLBACK[↩️ Auto Rollback<br/>Failure Detection]
    end

    IMAGE --> EKS
    IMAGE --> ECS
    IMAGE --> EC2

    EKS --> TERRAFORM
    EKS --> K8S_MANIFEST
    ECS --> ECS_TASK
    EC2 --> SSH_DEPLOY

    EKS --> LOAD_TEST
    ECS --> HEALTH_CHECK
    EC2 --> AUTO_ROLLBACK

    %% Styling
    classDef awsClass fill:#ff9800,stroke:#e65100,stroke-width:2px
    classDef infraClass fill:#2196f3,stroke:#0d47a1,stroke-width:2px
    classDef testClass fill:#4caf50,stroke:#1b5e20,stroke-width:2px

    class EKS,ECS,EC2 awsClass
    class TERRAFORM,K8S_MANIFEST,ECS_TASK,SSH_DEPLOY infraClass
    class LOAD_TEST,HEALTH_CHECK,AUTO_ROLLBACK testClass
```

### 📊 Deployment Comparison Matrix

| Strategy | Infrastructure | Scaling | Complexity | Cost | Use Case |
|----------|----------------|---------|------------|------|----------|
| **☸️ EKS** | Kubernetes | Auto-scaling | High | High | Production microservices |
| **🐳 ECS** | Managed containers | Task-based | Medium | Medium | Containerized apps |
| **🖥️ EC2** | Virtual machines | Manual | Low | Low | Simple deployments |

### � Detailed Deploy Flows

#### ☸️ EKS Deployment Flow

```mermaid
sequenceDiagram
    participant GHA as ⚡ GitHub Actions
    participant AWS as ☁️ AWS
    participant TF as 🏗️ Terraform
    participant EKS as ☸️ EKS Cluster
    participant K8S as 📄 Kubernetes

    GHA->>AWS: 1. Configure AWS credentials
    GHA->>TF: 2. Clone Infra_CI_Kubernetes
    TF->>AWS: 3. terraform init & apply
    AWS->>EKS: 4. Provision EKS cluster
    GHA->>K8S: 5. kubectl update-kubeconfig
    GHA->>K8S: 6. Create secrets (DB config)
    GHA->>K8S: 7. Apply go.yaml manifest
    GHA->>K8S: 8. Update image to latest tag
    K8S->>EKS: 9. Deploy new version
```

#### 🐳 ECS Deployment Flow

```mermaid
sequenceDiagram
    participant GHA as ⚡ GitHub Actions
    participant ECS as � ECS Service
    participant ALB as ⚖️ Load Balancer
    participant TASK as 📋 Task Definition

    GHA->>ECS: 1. Get current task definition
    GHA->>TASK: 2. Update image & environment
    GHA->>ECS: 3. Deploy new task definition
    ECS->>ALB: 4. Update service
    GHA->>ALB: 5. Health check request
    ALB-->>GHA: 6a. Success response
    ALB-->>GHA: 6b. Failure - trigger rollback
    GHA->>ECS: 7. Rollback to previous version (if failed)
```

#### 🖥️ EC2 Deployment Flow

```mermaid
sequenceDiagram
    participant GHA as ⚡ GitHub Actions
    participant S3 as 📦 Artifact Storage
    participant EC2 as 🖥️ EC2 Instance
    participant APP as 🚀 Go Application

    GHA->>S3: 1. Download binary artifact
    GHA->>EC2: 2. SSH connect with private key
    GHA->>EC2: 3. Deploy files (exclude postgres-data)
    GHA->>EC2: 4. Set environment variables
    GHA->>EC2: 5. chmod +x main
    GHA->>APP: 6. nohup ./main (background process)
    EC2->>APP: 7. Application starts on port 8000
```

### 🧪 Load Testing Strategy

```mermaid
graph TB
    TRIGGER[🎯 Load Test Trigger<br/>workflow_call]
    
    subgraph "🏗️ Infrastructure Setup"
        AWS_CREDS[🔐 AWS Credentials<br/>ID_CHAVE_ACESSO]
        CLONE_INFRA[📁 Clone Infra_CI<br/>GitHub Repository]
        TERRAFORM_SETUP[🏗️ Setup Terraform<br/>v2.0.3]
    end

    subgraph "🔄 Environment Lifecycle"
        TF_DESTROY1[💥 terraform destroy<br/>Clean previous]
        TF_APPLY[🚀 terraform apply<br/>Create environment]
        GET_ALB_IP[🌐 Get ALB IP<br/>Load Balancer endpoint]
        TF_DESTROY2[💥 terraform destroy<br/>Cleanup after test]
    end

    subgraph "⚡ Load Testing"
        PYTHON_SETUP[🐍 Setup Python 3.10<br/>pip install locust]
        CREATE_LOCUST[📝 Create locustfile.py<br/>Test scenarios]
        RUN_LOCUST[🔥 Run Load Test<br/>10 users, 60s, /bruno endpoint]
    end

    TRIGGER --> AWS_CREDS
    AWS_CREDS --> CLONE_INFRA
    CLONE_INFRA --> TERRAFORM_SETUP
    TERRAFORM_SETUP --> TF_DESTROY1
    TF_DESTROY1 --> TF_APPLY
    TF_APPLY --> GET_ALB_IP
    GET_ALB_IP --> PYTHON_SETUP
    PYTHON_SETUP --> CREATE_LOCUST
    CREATE_LOCUST --> RUN_LOCUST
    RUN_LOCUST --> TF_DESTROY2

    %% Styling
    classDef setupClass fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef infraClass fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef testClass fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px

    class AWS_CREDS,CLONE_INFRA,TERRAFORM_SETUP setupClass
    class TF_DESTROY1,TF_APPLY,GET_ALB_IP,TF_DESTROY2 infraClass
    class PYTHON_SETUP,CREATE_LOCUST,RUN_LOCUST testClass
```

### 🔧 Runtime Configuration by Environment

```mermaid
graph LR
    subgraph "☸️ EKS Configuration"
        EKS_SECRETS[🔐 Kubernetes Secrets<br/>dbhost, dbuser, dbpassword<br/>dbname, dbport, port]
        EKS_CONFIG[⚙️ kubectl apply<br/>go.yaml manifest]
        EKS_IMAGE[🐳 Image Update<br/>gabrielvieira/go_ci:tag]
    end

    subgraph "🐳 ECS Configuration"
        ECS_TASK_DEF[📋 Task Definition<br/>JSON configuration]
        ECS_ENV_VARS[🔧 Environment Variables<br/>HOST, USER, PASSWORD<br/>DBNAME, DBPORT, PORT]
        ECS_ROLLBACK[↩️ Auto Rollback<br/>Health check failure]
    end

    subgraph "🖥️ EC2 Configuration"
        EC2_SSH[🔑 SSH Private Key<br/>Remote access]
        EC2_ENV_EXPORT[📤 Export Variables<br/>Runtime environment]
        EC2_BINARY[⚙️ Binary Execution<br/>nohup ./main &]
    end

    EKS_SECRETS --> EKS_CONFIG
    EKS_CONFIG --> EKS_IMAGE
    
    ECS_TASK_DEF --> ECS_ENV_VARS
    ECS_ENV_VARS --> ECS_ROLLBACK
    
    EC2_SSH --> EC2_ENV_EXPORT
    EC2_ENV_EXPORT --> EC2_BINARY
```

## 📈 Métricas e Monitoramento

```mermaid
graph TB
    subgraph "📊 Pipeline Metrics"
        BUILD_TIME[⏱️ Build Time<br/>~3-5 min]
        TEST_COVERAGE[📈 Test Coverage<br/>>80%]
        SUCCESS_RATE[✅ Success Rate<br/>>95%]
    end

    subgraph "🐳 Container Metrics"
        IMAGE_SIZE[📦 Image Size<br/>~50MB]
        STARTUP_TIME[🚀 Startup Time<br/>~2-5s]
        MEMORY_USAGE[💾 Memory Usage<br/>~64MB]
    end

    subgraph "🔄 Deployment Metrics"
        DEPLOY_FREQ[📅 Deploy Frequency<br/>Multiple/day]
        ROLLBACK_TIME[⏪ Rollback Time<br/>~1-2 min]
        UPTIME[⬆️ Uptime<br/>>99.9%]
    end

    BUILD_TIME --> IMAGE_SIZE
    TEST_COVERAGE --> STARTUP_TIME
    SUCCESS_RATE --> MEMORY_USAGE
    IMAGE_SIZE --> DEPLOY_FREQ
    STARTUP_TIME --> ROLLBACK_TIME
    MEMORY_USAGE --> UPTIME
```

---

## 🚀 Como Usar Este Diagrama

1. **Para Novos Desenvolvedores**: Entender o fluxo completo
2. **Para DevOps**: Otimizar pipeline e infraestrutura
3. **Para Stakeholders**: Visualizar processo de entrega
4. **Para Troubleshooting**: Identificar pontos de falha

**💡 Dica**: Use este diagrama em apresentações e documentação técnica!
