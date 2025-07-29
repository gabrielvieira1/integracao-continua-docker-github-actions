# 🏗️ Arquitetura e Fluxo de Deploy

## 📊 Visão Geral da Infraestrutura

```mermaid
graph TB
    subgraph "🔧 Desenvolvimento Local"
        DEV[👨‍💻 Desenvolvedor]
        LOCAL[💻 Ambiente Local]
        MAKE[🛠️ Makefile]
        DOCKER_LOCAL[🐳 Docker Compose]
        DB_LOCAL[🐘 PostgreSQL Local]
        TESTS[🧪 Testes Locais]
    end

    subgraph "☁️ GitHub Repository"
        REPO[📁 Repositório Main]
        ACTIONS[⚡ GitHub Actions]
        SECRETS[🔐 GitHub Secrets]
        ARTIFACTS[📦 Build Artifacts]
        WORKFLOWS[📋 6 Workflows]
    end

    subgraph "🏭 CI/CD Pipeline Jobs"
        WORKFLOW_GO[🧪 go.yml - Pipeline Principal]
        WORKFLOW_DOCKER[🐳 Docker.yml - Build & Push]
        WORKFLOW_EC2[🖥️ EC2.yml - Deploy EC2]
        WORKFLOW_ECS[🐳 ECS.yml - Deploy ECS]
        WORKFLOW_EKS[☸️ EKS.yml - Deploy EKS]
        WORKFLOW_LOAD[⚡ LoadTest.yml - Performance]
    end

    subgraph "🌐 Container Registry"
        DOCKER_HUB[🐳 Docker Hub<br/>gabrielvieira/go_ci]
        IMAGE_TAGS[🏷️ Tagged Images<br/>main, dev, staging]
    end

    subgraph "☁️ AWS Infrastructure"
        subgraph "🖥️ EC2 Environment"
            EC2_INSTANCE[🖥️ EC2 Instance<br/>t2.micro]
            RDS_DB[🗃️ RDS PostgreSQL<br/>13.21]
            SEC_GROUPS[🛡️ Security Groups<br/>App + DB]
        end
        
        subgraph "🐳 ECS Environment"
            ECS_CLUSTER[🐳 ECS Fargate<br/>Cluster]
            ALB[⚖️ Application<br/>Load Balancer]
            ECS_SERVICE[� ECS Service<br/>Auto-scaling]
        end
        
        subgraph "☸️ EKS Environment"
            EKS_CLUSTER[☸️ EKS Cluster<br/>Kubernetes]
            NODE_GROUPS[🖥️ Node Groups<br/>Worker Nodes]
            K8S_PODS[🎯 Pods<br/>Application]
        end
    end

    subgraph "🏗️ Infrastructure as Code"
        TERRAFORM[🏗️ Terraform Modules]
        KUSTOMIZE[☸️ Kustomize<br/>K8s Manifests]
        SCRIPTS[📜 Automation Scripts]
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
    ACTIONS --> WORKFLOWS
    WORKFLOWS --> WORKFLOW_GO
    WORKFLOW_GO --> WORKFLOW_DOCKER
    WORKFLOW_DOCKER --> DOCKER_HUB
    DOCKER_HUB --> IMAGE_TAGS

    %% Deploy workflows
    WORKFLOWS --> WORKFLOW_EC2
    WORKFLOWS --> WORKFLOW_ECS
    WORKFLOWS --> WORKFLOW_EKS
    WORKFLOWS --> WORKFLOW_LOAD

    %% Infrastructure provisioning
    WORKFLOW_EC2 --> TERRAFORM
    WORKFLOW_ECS --> TERRAFORM
    WORKFLOW_EKS --> TERRAFORM
    WORKFLOW_EKS --> KUSTOMIZE
    
    TERRAFORM --> EC2_INSTANCE
    TERRAFORM --> RDS_DB
    TERRAFORM --> SEC_GROUPS
    TERRAFORM --> ECS_CLUSTER
    TERRAFORM --> ALB
    TERRAFORM --> ECS_SERVICE
    TERRAFORM --> EKS_CLUSTER
    TERRAFORM --> NODE_GROUPS
    
    KUSTOMIZE --> K8S_PODS

    %% Deploy destinations
    WORKFLOW_EC2 --> EC2_INSTANCE
    WORKFLOW_ECS --> ECS_SERVICE
    WORKFLOW_EKS --> K8S_PODS
    WORKFLOW_LOAD --> EC2_INSTANCE

    ARTIFACTS --> WORKFLOW_EC2
    IMAGE_TAGS --> ECS_SERVICE
    IMAGE_TAGS --> K8S_PODS

    %% Scripts
    SCRIPTS --> TERRAFORM

    %% Styling
    classDef devClass fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef githubClass fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef cicdClass fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef awsClass fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef infraClass fill:#fce4ec,stroke:#880e4f,stroke-width:2px

    class DEV,LOCAL,MAKE,DOCKER_LOCAL,DB_LOCAL,TESTS devClass
    class REPO,ACTIONS,SECRETS,ARTIFACTS,WORKFLOWS githubClass
    class WORKFLOW_GO,WORKFLOW_DOCKER,WORKFLOW_EC2,WORKFLOW_ECS,WORKFLOW_EKS,WORKFLOW_LOAD cicdClass
    class DOCKER_HUB,IMAGE_TAGS,EC2_INSTANCE,RDS_DB,SEC_GROUPS,ECS_CLUSTER,ALB,ECS_SERVICE,EKS_CLUSTER,NODE_GROUPS,K8S_PODS awsClass
    class TERRAFORM,KUSTOMIZE,SCRIPTS infraClass
```
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

## 🔄 Fluxo Detalhado dos Workflows

### 🧪 Workflow Principal (go.yml)

```mermaid
flowchart TD
    START([👨‍💻 Developer Push])
    
    subgraph "🧪 Test Job"
        CHECKOUT1[📥 Checkout Code]
        SETUP_GO[🔧 Setup Go Matrix<br/>1.20 & 1.21]
        BUILD_APP[🔨 Build Go App]
        BUILD_DB[🐘 Build PostgreSQL Container]
        START_DB[▶️ Start Database]
        WAIT_DB[⏳ Wait DB Ready]
        RUN_TESTS[🧪 Run Integration Tests]
    end

    subgraph "🔨 Build Job"
        CHECKOUT2[📥 Checkout Code]
        COMPILE[⚙️ Compile Go Binary]
        UPLOAD[📤 Upload Artifact]
    end

    subgraph "🐳 Docker Job Call"
        CALL_DOCKER[🔄 Call Docker.yml Workflow]
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
    
    UPLOAD --> CALL_DOCKER
    CALL_DOCKER --> SUCCESS

    %% Styling
    classDef testClass fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef buildClass fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef dockerClass fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef startClass fill:#f1f8e9,stroke:#558b2f,stroke-width:3px
    classDef endClass fill:#ffebee,stroke:#c62828,stroke-width:3px

    class CHECKOUT1,SETUP_GO,BUILD_APP,BUILD_DB,START_DB,WAIT_DB,RUN_TESTS testClass
    class CHECKOUT2,COMPILE,UPLOAD buildClass
    class CALL_DOCKER dockerClass
    class START startClass
    class SUCCESS,FAIL endClass
```

### � Workflows de Deploy

```mermaid
flowchart LR
    subgraph "🎯 Deploy Strategies"
        DOCKER_IMAGE[🐳 Docker Image<br/>gabrielvieira/go_ci:latest]
        GO_BINARY[📱 Go Binary<br/>./main executable]
    end
    
    subgraph "🖥️ EC2 Deployment"
        EC2_WORKFLOW[📋 EC2.yml]
        EC2_SSH[🔑 SSH Deploy]
        EC2_INSTANCE[�️ EC2 Instance<br/>Direct binary execution]
        EC2_RDS[🗃️ RDS PostgreSQL<br/>Database connection]
    end
    
    subgraph "🐳 ECS Deployment"
        ECS_WORKFLOW[📋 ECS.yml]
        ECS_TERRAFORM[🏗️ Terraform Apply]
        ECS_SERVICE[� ECS Fargate Service<br/>Container orchestration]
        ECS_ALB[⚖️ Application Load Balancer]
    end
    
    subgraph "☸️ EKS Deployment"
        EKS_WORKFLOW[📋 EKS.yml]
        EKS_KUBECTL[☸️ kubectl apply]
        EKS_PODS[🎯 Kubernetes Pods<br/>Container orchestration]
        EKS_INGRESS[🌐 Ingress Controller]
    end
    
    subgraph "⚡ Load Testing"
        LOAD_WORKFLOW[📋 LoadTest.yml]
        TEMP_INFRA[🏗️ Temporary Infrastructure]
        LOCUST_TEST[🐍 Locust Performance Test]
        CLEANUP[💥 Resource Cleanup]
    end

    %% Connections
    GO_BINARY --> EC2_SSH
    EC2_WORKFLOW --> EC2_SSH
    EC2_SSH --> EC2_INSTANCE
    EC2_INSTANCE --> EC2_RDS
    
    DOCKER_IMAGE --> ECS_SERVICE
    ECS_WORKFLOW --> ECS_TERRAFORM
    ECS_TERRAFORM --> ECS_SERVICE
    ECS_SERVICE --> ECS_ALB
    
    DOCKER_IMAGE --> EKS_PODS
    EKS_WORKFLOW --> EKS_KUBECTL
    EKS_KUBECTL --> EKS_PODS
    EKS_PODS --> EKS_INGRESS
    
    LOAD_WORKFLOW --> TEMP_INFRA
    TEMP_INFRA --> LOCUST_TEST
    LOCUST_TEST --> CLEANUP

    %% Styling
    classDef imageClass fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef ec2Class fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef ecsClass fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef eksClass fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef loadClass fill:#fce4ec,stroke:#880e4f,stroke-width:2px

    class DOCKER_IMAGE,GO_BINARY imageClass
    class EC2_WORKFLOW,EC2_SSH,EC2_INSTANCE,EC2_RDS ec2Class
    class ECS_WORKFLOW,ECS_TERRAFORM,ECS_SERVICE,ECS_ALB ecsClass
    class EKS_WORKFLOW,EKS_KUBECTL,EKS_PODS,EKS_INGRESS eksClass
    class LOAD_WORKFLOW,TEMP_INFRA,LOCUST_TEST,CLEANUP loadClass
```
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

## �️ Infraestrutura como Código

### 🏭 Terraform Modules Architecture

```mermaid
graph TB
    subgraph "� infra/terraform/modules/"
        subgraph "�🖥️ ec2-infrastructure"
            EC2_MAIN[📄 main.tf<br/>EC2 + RDS + Security Groups]
            EC2_VARS[⚙️ variables.tf<br/>AMI, Subnets, DB Config]
            EC2_OUT[📤 outputs.tf<br/>Instance IP, RDS Endpoint]
        end
        
        subgraph "🐳 ecs-infrastructure"
            ECS_MAIN[📄 main.tf<br/>ECS + ALB + Target Groups]
            ECS_VARS[⚙️ variables.tf<br/>Container Config, Image]
            ECS_OUT[📤 outputs.tf<br/>ALB DNS, Service ARN]
        end
        
        subgraph "☸️ eks-cluster"
            EKS_MAIN[📄 main.tf<br/>EKS + Node Groups + IRSA]
            EKS_VARS[⚙️ variables.tf<br/>K8s Version, Node Config]
            EKS_OUT[📤 outputs.tf<br/>Cluster Endpoint, Config]
        end
    end

    subgraph "📁 infra/terraform/environments/"
        DEV_ENV[🧪 dev/<br/>Development Environment]
        ECS_DEV[🐳 ecs-dev/<br/>ECS Development] 
        STAGING_ENV[🎭 staging/<br/>Staging Environment]
        PROD_ENV[🚀 prod/<br/>Production Environment]
    end

    subgraph "☸️ infra/k8s/"
        subgraph "📁 base/"
            K8S_DEPLOY[📄 deployment.yaml<br/>App Deployment]
            K8S_SVC[📄 service.yaml<br/>Internal Service]
            K8S_KUST[📄 kustomization.yaml<br/>Base Configuration]
        end
        
        subgraph "📁 overlays/"
            K8S_DEV[🧪 dev/<br/>Dev Customizations]
            K8S_STAGING[🎭 staging/<br/>Staging Customizations]
            K8S_PROD[🚀 prod/<br/>Prod Customizations]
        end
    end

    subgraph "� infra/scripts/"
        CREATE_SCRIPT[🔧 create_unified_terraform.sh<br/>Provision All Infrastructure]
        DESTROY_SCRIPT[💥 destroy_unified_terraform.sh<br/>Cleanup All Resources]
        DEPLOY_SCRIPT[🚀 deploy.sh<br/>Environment-specific Deploy]
    end

    %% Module relationships
    DEV_ENV --> EC2_MAIN
    DEV_ENV --> EC2_VARS
    ECS_DEV --> ECS_MAIN
    ECS_DEV --> ECS_VARS
    STAGING_ENV --> EKS_MAIN
    STAGING_ENV --> EKS_VARS
    PROD_ENV --> EKS_MAIN
    PROD_ENV --> EKS_VARS

    %% Kubernetes relationships
    K8S_DEV --> K8S_DEPLOY
    K8S_STAGING --> K8S_DEPLOY
    K8S_PROD --> K8S_DEPLOY
    K8S_DEV --> K8S_SVC
    K8S_STAGING --> K8S_SVC
    K8S_PROD --> K8S_SVC

    %% Script relationships
    CREATE_SCRIPT --> DEV_ENV
    CREATE_SCRIPT --> ECS_DEV
    CREATE_SCRIPT --> STAGING_ENV
    DESTROY_SCRIPT --> DEV_ENV
    DESTROY_SCRIPT --> ECS_DEV
    DESTROY_SCRIPT --> STAGING_ENV

    %% Styling
    classDef moduleClass fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef envClass fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef k8sClass fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef scriptClass fill:#fce4ec,stroke:#880e4f,stroke-width:2px

    class EC2_MAIN,EC2_VARS,EC2_OUT,ECS_MAIN,ECS_VARS,ECS_OUT,EKS_MAIN,EKS_VARS,EKS_OUT moduleClass
    class DEV_ENV,ECS_DEV,STAGING_ENV,PROD_ENV envClass
    class K8S_DEPLOY,K8S_SVC,K8S_KUST,K8S_DEV,K8S_STAGING,K8S_PROD k8sClass
    class CREATE_SCRIPT,DESTROY_SCRIPT,DEPLOY_SCRIPT scriptClass
```

### 🐳 Container Environments

```mermaid
graph TB
    subgraph "🖥️ Desenvolvimento Local"
        subgraph "🐳 Docker Compose Stack"
            APP_LOCAL[🚀 Go App Container<br/>Port: 8000<br/>Volume: ./volume]
            DB_LOCAL[🐘 PostgreSQL 13<br/>Port: 5432<br/>Persistent Volume]
            PGADMIN_LOCAL[🔧 PgAdmin 4<br/>Port: 54321<br/>Web Interface]
        end
        ENV_LOCAL[📄 .env file<br/>Local environment variables]
        MAKEFILE[🛠️ Makefile<br/>Development automation]
    end

    subgraph "☁️ GitHub Actions CI"
        subgraph "🧪 Test Environment" 
            RUNNER[🏃‍♂️ Ubuntu 22.04 Runner]
            DB_CI[🐘 PostgreSQL Service<br/>Test Database Container]
            GO_TEST[🧪 Go Test Matrix<br/>Go 1.20 & 1.21]
        end
        SECRETS_CI[🔐 GitHub Secrets<br/>CI/CD credentials]
        ARTIFACTS[📦 Build Artifacts<br/>Compiled Go binary]
    end

    subgraph "🌐 Container Registry"
        DOCKER_HUB_REG[🐳 Docker Hub Registry<br/>gabrielvieira/go_ci]
        subgraph "📦 Image Layers"
            UBUNTU_BASE[🐧 Ubuntu 22.04 Base]
            GO_BINARY[⚙️ Go Binary Executable]
            APP_CONFIG[⚙️ Application Config]
            RUNTIME_DEPS[📚 Runtime Dependencies]
        end
    end

    subgraph "☁️ AWS Production Environments"
        subgraph "🖥️ EC2 Direct Deploy"
            EC2_INSTANCE[�️ EC2 t2.micro<br/>Direct binary execution]
            RDS_POSTGRES[�️ RDS PostgreSQL 13<br/>Managed database]
        end
        
        subgraph "🐳 ECS Fargate"
            ECS_CLUSTER[🐳 ECS Cluster<br/>Serverless containers]
            ALB_ECS[⚖️ Application Load Balancer<br/>Traffic distribution]
            ECS_TASKS[📋 ECS Tasks<br/>Auto-scaling containers]
        end
        
        subgraph "☸️ EKS Kubernetes"
            EKS_CLUSTER[☸️ EKS Cluster<br/>Managed Kubernetes]
            NODE_GROUPS[🖥️ Worker Node Groups<br/>t3.medium instances]
            PODS[🎯 Application Pods<br/>Kubernetes deployments]
        end
    end

    %% Development flow
    ENV_LOCAL --> APP_LOCAL
    ENV_LOCAL --> DB_LOCAL
    APP_LOCAL --> DB_LOCAL
    DB_LOCAL --> PGADMIN_LOCAL
    MAKEFILE --> APP_LOCAL

    %% CI flow
    SECRETS_CI --> RUNNER
    RUNNER --> DB_CI
    RUNNER --> GO_TEST
    GO_TEST --> DB_CI
    RUNNER --> ARTIFACTS

    %% Registry flow  
    ARTIFACTS --> DOCKER_HUB_REG
    UBUNTU_BASE --> DOCKER_HUB_REG
    GO_BINARY --> DOCKER_HUB_REG
    APP_CONFIG --> DOCKER_HUB_REG
    RUNTIME_DEPS --> DOCKER_HUB_REG

    %% Production deployments
    ARTIFACTS --> EC2_INSTANCE
    EC2_INSTANCE --> RDS_POSTGRES
    
    DOCKER_HUB_REG --> ECS_TASKS
    ECS_TASKS --> ALB_ECS
    ECS_CLUSTER --> ECS_TASKS
    
    DOCKER_HUB_REG --> PODS
    EKS_CLUSTER --> NODE_GROUPS
    NODE_GROUPS --> PODS

    %% Styling
    classDef localClass fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef ciClass fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef registryClass fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef awsClass fill:#ffebee,stroke:#c62828,stroke-width:2px

    class APP_LOCAL,DB_LOCAL,PGADMIN_LOCAL,ENV_LOCAL,MAKEFILE localClass
    class RUNNER,DB_CI,GO_TEST,SECRETS_CI,ARTIFACTS ciClass
    class DOCKER_HUB_REG,UBUNTU_BASE,GO_BINARY,APP_CONFIG,RUNTIME_DEPS registryClass
    class EC2_INSTANCE,RDS_POSTGRES,ECS_CLUSTER,ALB_ECS,ECS_TASKS,EKS_CLUSTER,NODE_GROUPS,PODS awsClass
```
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
