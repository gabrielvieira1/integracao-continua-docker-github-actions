# Análise: Estrutura EKS vs EC2/ECS e Explicação das Pastas

## 🔍 **Problema Identificado**

Você está correto! O EKS.yml original não seguia o padrão dos workflows EC2 e ECS. Aqui está a análise:

### **❌ EKS.yml Original (Problemático)**
```yaml
# Usava inputs e environment variables
environment: ${{ inputs.environment }}
env:
  AWS_REGION: ${{ vars.AWS_REGION || 'us-east-1' }}
  EKS_CLUSTER_NAME: ${{ vars.EKS_CLUSTER_NAME }}
  DB_HOST: ${{ vars.DB_HOST }}
```

### **✅ EC2.yml e ECS.yml (Padrão Correto)**
```yaml
# Usam environment DEV hardcoded e buscam recursos da AWS
environment: DEV
env:
  AWS_REGION: us-east-1
  EC2_INSTANCE_TAG_NAME: api-go-dev-ec2-bastion
  ECS_CLUSTER_NAME: api-go-dev-ecs-cluster
  RDS_INSTANCE_ID: api-go-dev-rds-main
```

## 🏗️ **Diferenças na Estrutura de Infraestrutura**

### **Infra_CI_Kubernetes (Antiga)**
```
Infra_CI_Kubernetes/
├── env/
│   └── Homolog/           # Environment específico
│       ├── Main.tf        # Simples, só chama módulo
│       └── Backend.tf     # S3 backend
└── infra/                 # Módulos terraform
    ├── EKS.tf            # Cluster EKS
    ├── VPC.tf            # Rede
    ├── RDS.tf            # Database
    └── GrupoSeguranca.tf # Security Groups
```

### **Nova Estrutura do Projeto**
```
infra/
├── k8s/                   # 📁 Manifestos Kubernetes
│   ├── base/             # Deployments, Services base
│   └── overlays/         # Customizações por ambiente
└── terraform/            # 📁 Infraestrutura como código
    ├── modules/
    │   └── eks-cluster/  # Módulo para criar cluster
    └── environments/
        ├── dev/          # Ambiente DEV
        ├── staging/      # Ambiente STAGING  
        └── prod/         # Ambiente PROD
```

## 💡 **Explicação: Por que duas pastas?**

### **1. `infra/k8s/`** - Manifestos Kubernetes (DEPLOYMENT)
- **Propósito**: Define COMO a aplicação roda no cluster
- **Conteúdo**: Deployments, Services, ConfigMaps, Secrets
- **Momento**: Usado APÓS o cluster estar criado
- **Exemplo**: `deployment.yaml`, `service.yaml`

### **2. `infra/terraform/modules/eks-cluster/`** - Infraestrutura (CRIAÇÃO)
- **Propósito**: Define como CRIAR o cluster EKS
- **Conteúdo**: VPC, EKS cluster, Node groups, RDS
- **Momento**: Usado ANTES de fazer deploy da aplicação
- **Exemplo**: `main.tf`, `security_groups.tf`

## 🔄 **Fluxo Correto**

```bash
# 1. CRIAR infraestrutura (uma vez)
cd infra/terraform/environments/dev
terraform apply

# 2. DEPLOYAR aplicação (múltiplas vezes) 
# GitHub Actions EKS.yml usa infra/k8s/
```

## ⚡ **EKS.yml Corrigido - Principais Mudanças**

### **1. Environment Strategy**
```yaml
# ❌ Antes (inputs dinâmicos)
environment: ${{ inputs.environment }}

# ✅ Agora (DEV hardcoded como EC2/ECS)
environment: DEV
```

### **2. Resource Discovery**
```yaml
# ❌ Antes (variables não existentes)
EKS_CLUSTER_NAME: ${{ vars.EKS_CLUSTER_NAME }}

# ✅ Agora (nomes hardcoded como EC2/ECS)
EKS_CLUSTER_NAME: go-api-dev-eks-cluster
RDS_INSTANCE_ID: api-go-dev-rds-main
```

### **3. Database Connection**
```yaml
# ❌ Antes (env variables diretas)
DB_HOST: ${{ env.DB_HOST }}

# ✅ Agora (busca do RDS como EC2)
DB_HOST: ${{ steps.get_rds_details.outputs.DB_HOST }}
```

### **4. Validation Strategy**
```yaml
# ✅ Adicionado: Verifica se cluster existe
CLUSTER_STATUS=$(aws eks describe-cluster --name ${{ env.EKS_CLUSTER_NAME }} ...)
if [ "$CLUSTER_STATUS" = "NOT_FOUND" ]; then
  echo "💡 Please create the EKS infrastructure first using Terraform"
  exit 1
fi
```

## 🛠️ **Compatibilidade da Infraestrutura**

### **Comparação: Antiga vs Nova**

| Componente | Infra_CI_Kubernetes | Nova Estrutura | ✅ Compatível |
|------------|---------------------|----------------|---------------|
| **EKS Cluster** | ✅ module "eks" | ✅ module "eks" | ✅ |
| **VPC** | ✅ module "vpc" | ✅ module "vpc" | ✅ |
| **RDS** | ✅ aws_db_instance | ✅ module "rds" | ✅ |
| **Security Groups** | ✅ Manual | ✅ Modular | ✅ |
| **Node Groups** | ✅ eks_managed_node_groups | ✅ eks_managed_node_groups | ✅ |

### **Melhorias na Nova Estrutura**

1. **🔒 Segurança**: Node groups em subnets privadas
2. **📊 Monitoramento**: Add-ons essenciais (EBS CSI, VPC CNI)
3. **🏷️ Tags**: Kubernetes tags automáticas
4. **🌐 Networking**: Database sem internet gateway
5. **📈 Escalabilidade**: Multi-AZ para produção

## 🎯 **Próximos Passos**

1. **✅ EKS.yml corrigido** - Segue padrão EC2/ECS
2. **📋 Criar namespace dev** - `infra/k8s/overlays/dev/`
3. **🏗️ Deploy infraestrutura** - Terraform EKS module
4. **🧪 Testar pipeline** - EKS deployment

## 🔗 **Integração com go.yml**

```yaml
# go.yml deve chamar EKS sem inputs (como EC2/ECS)
Deploy_EKS:
  needs: docker
  uses: ./.github/workflows/EKS.yml
  secrets: inherit
```

A nova estrutura mantém consistência entre as três estratégias (EC2, ECS, EKS) e permite separação clara entre criação de infraestrutura e deployment da aplicação.
