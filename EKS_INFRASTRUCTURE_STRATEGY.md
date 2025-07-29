# Estratégia de Infraestrutura: EKS Separado vs Reutilizado

## 🎯 **Decisão Final: EKS Infraestrutura SEPARADA**

### **✅ Por que Separar a Infraestrutura do EKS?**

#### **1. 🏗️ Arquitetural**
- **VPC Tags**: EKS precisa de tags específicas (`kubernetes.io/cluster/name`)
- **Subnet Tags**: Load Balancers precisam de tags `kubernetes.io/role/elb`
- **Security Groups**: EKS tem regras específicas (nodes ↔ cluster ↔ pods)
- **CIDR Blocks**: Evita conflitos com VPC default

#### **2. 🔒 Segurança**
- **Isolamento**: Database EKS isolado do EC2/ECS
- **Network Policies**: Kubernetes pode implementar políticas de rede
- **Access Control**: RBAC específico do Kubernetes

#### **3. 🛠️ Operacional**
- **Deploy Independente**: EKS pode ser updated sem afetar EC2/ECS
- **Rollback**: Problemas no EKS não afetam outras estratégias
- **Scaling**: Recursos dimensionados especificamente para containers

## 📊 **Comparação: Estratégias de Infraestrutura**

| Componente | EC2 | ECS | EKS |
|------------|-----|-----|-----|
| **VPC** | Default | Default (reutiliza) | Nova (dedicada) |
| **RDS** | Criado | Reutiliza EC2 | Novo (separado) |
| **Security Groups** | Criados | Reutiliza EC2 | Novos (específicos K8s) |
| **Load Balancer** | ALB | ALB (reutiliza) | AWS LB Controller |
| **Subnets** | Default | Default | Private/Public/DB |
| **Benefício** | Simples | Econômico | Isolado/Seguro |

## 🏗️ **Estrutura Final do Terraform**

### **environments/dev/main.tf**
```terraform
# ESTRATÉGIA 1: EC2 (Base)
module "ec2_infrastructure" {
  vpc_id = data.aws_vpc.default.id    # VPC default
  # Cria: EC2, RDS, Security Groups, ALB
}

# ESTRATÉGIA 2: ECS (Reutiliza EC2)  
module "ecs_infrastructure" {
  vpc_id = data.aws_vpc.default.id    # Mesmo VPC do EC2
  db_host = module.ec2_infrastructure.rds_endpoint  # Mesmo RDS
  existing_api_sg_id = module.ec2_infrastructure.security_group_api_id
  # Cria: ECS Cluster, Task Definition, Service
}

# ESTRATÉGIA 3: EKS (Independente)
module "eks_infrastructure" {
  # Cria: VPC nova, EKS Cluster, RDS novo, Security Groups específicos
  vpc_cidr = "10.1.0.0/16"           # VPC dedicada
  cluster_name = "go-api-dev-eks-cluster"
}
```

## 🔄 **Fluxo de Deploy EKS Corrigido**

### **1. ✅ Criar Infraestrutura (Terraform)**
```bash
cd infra/terraform/environments/dev
terraform apply
# Cria: VPC (10.1.0.0/16), EKS cluster, RDS novo
```

### **2. ✅ Deploy Aplicação (GitHub Actions)**
```yaml
# EKS.yml busca recursos por nome:
EKS_CLUSTER_NAME: go-api-dev-eks-cluster
RDS_INSTANCE_ID: go-api-dev-eks-cluster-db  # RDS específico do EKS
```

## 🛡️ **Security Groups Específicos do EKS**

### **Criados pelo Módulo eks-cluster**
```terraform
# 1. EKS Cluster Security Group
aws_security_group.eks_cluster_sg
# Regras: API Server (443), comunicação com nodes

# 2. Node Group Security Group  
aws_security_group.node_group_sg
# Regras: comunicação entre pods, acesso internet

# 3. RDS Security Group
aws_security_group.rds_sg
# Regras: PostgreSQL (5432) apenas de nodes EKS
```

### **Tags Kubernetes Necessárias**
```terraform
tags = {
  "kubernetes.io/cluster/${cluster_name}" = "shared"
  "kubernetes.io/role/elb" = "1"                    # Public subnets
  "kubernetes.io/role/internal-elb" = "1"           # Private subnets
}
```

## 📦 **Recursos Criados por Estratégia**

### **EC2 Strategy**
- ✅ VPC: Default
- ✅ RDS: `api-go-dev-rds-main` 
- ✅ EC2: `api-go-dev-ec2-bastion`
- ✅ ALB: `api-go-dev-alb-app`

### **ECS Strategy (Reutiliza EC2)**
- ✅ VPC: Default (mesmo)
- ✅ RDS: `api-go-dev-rds-main` (mesmo)
- ✅ ECS Cluster: `api-go-dev-ecs-cluster`
- ✅ ALB: `api-go-dev-alb-app` (mesmo)

### **EKS Strategy (Nova Infraestrutura)**  
- ✅ VPC: `go-api-dev-eks-cluster-vpc` (10.1.0.0/16)
- ✅ RDS: `go-api-dev-eks-cluster-db` (novo)
- ✅ EKS: `go-api-dev-eks-cluster`
- ✅ ALB: AWS Load Balancer Controller

## 🔍 **Identificação de Recursos no Workflow**

### **EKS.yml - Resource Discovery**
```yaml
env:
  EKS_CLUSTER_NAME: go-api-dev-eks-cluster
  RDS_INSTANCE_ID: go-api-dev-eks-cluster-db  # Específico EKS

steps:
  - name: Validate EKS Cluster
    # aws eks describe-cluster --name go-api-dev-eks-cluster
    
  - name: Get RDS Details  
    # aws rds describe-db-instances --db-instance-identifier go-api-dev-eks-cluster-db
```

## 💰 **Considerações de Custo**

### **✅ Vantagens da Separação**
- **Controle Granular**: Pode destruir EKS sem afetar EC2/ECS
- **Otimização**: Dimensionar recursos especificamente para K8s
- **Multi-tenancy**: Diferentes equipes podem gerenciar estratégias

### **📊 Custo Estimado (us-east-1)**
```
EC2 Strategy:  
- t3.micro EC2: $8/mês
- db.t3.micro RDS: $15/mês
- ALB: $20/mês
Total: ~$43/mês

ECS Strategy (reutiliza):
- Fargate tasks: ~$10/mês (adicional)

EKS Strategy (separado):
- EKS cluster: $73/mês
- t3.medium nodes (2x): $30/mês  
- db.t3.micro RDS: $15/mês
Total: ~$118/mês adicional
```

## 🚀 **Próximos Passos**

1. **✅ EKS.yml Corrigido** - YAML válido, estratégia separada
2. **📋 Terraform Atualizado** - Módulo EKS adicionado ao dev/main.tf
3. **🏗️ Deploy Infraestrutura** - `terraform apply` para criar recursos EKS
4. **🧪 Testar Pipeline** - GitHub Actions com cluster real

A estratégia separada é a abordagem correta para produção, garantindo isolamento, segurança e flexibilidade operacional!
