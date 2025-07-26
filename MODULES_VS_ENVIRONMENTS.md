# 📖 Guia: Terraform Modules vs Environments

## 🤔 **Qual a diferença entre Modules e Environments?**

### 📁 **MODULES** (`infra/terraform/modules/`)
**São componentes reutilizáveis de infraestrutura.**

- ✅ **Reutilizáveis** - Podem ser usados em múltiplos ambientes
- ✅ **Modulares** - Cada módulo tem uma responsabilidade específica
- ✅ **Parametrizáveis** - Recebem variáveis para customização
- ✅ **Versionáveis** - Podem ter versões diferentes

**Exemplo dos nossos módulos:**
```
modules/
├── ec2-infrastructure/     # Módulo para EC2 + RDS
│   ├── main.tf            # Recursos: EC2, RDS, Security Groups
│   ├── variables.tf       # Parâmetros de entrada
│   └── outputs.tf         # Valores de saída
└── ecs-infrastructure/     # Módulo para ECS + ALB
    ├── main.tf            # Recursos: ECS, ALB, Task Definition
    ├── variables.tf       # Parâmetros de entrada
    └── outputs.tf         # Valores de saída
```

### 🌍 **ENVIRONMENTS** (`infra/terraform/environments/`)
**São instâncias específicas dos módulos para cada ambiente.**

- ✅ **Específicos** - Um por ambiente (dev, staging, prod)
- ✅ **Configuradores** - Definem como usar os módulos
- ✅ **Estados separados** - Cada ambiente tem seu próprio state
- ✅ **Valores concretos** - Definem valores específicos para cada ambiente

**Exemplo dos nossos ambientes:**
```
environments/
├── dev/                   # Ambiente de desenvolvimento
│   ├── main.tf           # Usa os módulos com configurações de dev
│   ├── variables.tf      # Variáveis específicas do dev
│   ├── outputs.tf        # Outputs do ambiente dev
│   └── terraform.tfstate # Estado específico do dev
├── staging/              # Ambiente de testes (futuro)
└── prod/                 # Ambiente de produção (futuro)
```

## 🏗️ **Nossa Arquitetura Atual**

### **1. Ambiente Unificado DEV**
```
environments/dev/
├── main.tf              # Chama AMBOS os módulos:
│                        #   - ec2-infrastructure
│                        #   - ecs-infrastructure
├── variables.tf         # Todas as variáveis (EC2 + ECS)
├── outputs.tf           # Todos os outputs (EC2 + ECS)
└── terraform.tfstate    # Estado único com EC2 + ECS
```

### **2. Módulos Especializados**
```
modules/
├── ec2-infrastructure/   # Responsável por:
│   ├── main.tf          #   - EC2 Instance
│   ├── variables.tf     #   - RDS PostgreSQL
│   └── outputs.tf       #   - Security Groups (API + RDS)
│
└── ecs-infrastructure/   # Responsável por:
    ├── main.tf          #   - ECS Cluster
    ├── variables.tf     #   - ECS Service + Task Definition
    └── outputs.tf       #   - ALB + Target Group
                         #   - Reutiliza SG do EC2
```

## 🔗 **Como os Módulos se Comunicam**

### **Compartilhamento via Outputs:**
```hcl
# No ambiente dev/main.tf:

# Módulo EC2 cria RDS e Security Groups
module "ec2_infrastructure" {
  source = "../../modules/ec2-infrastructure"
  # ... configurações
}

# Módulo ECS usa outputs do EC2
module "ecs_infrastructure" {
  source = "../../modules/ecs-infrastructure"
  
  # Usa endpoint do RDS criado pelo EC2
  db_host = module.ec2_infrastructure.rds_endpoint
  db_port = module.ec2_infrastructure.rds_port
  
  # Reutiliza Security Groups do EC2
  existing_api_sg_id = module.ec2_infrastructure.security_group_api_id
  existing_rds_sg_id = module.ec2_infrastructure.security_group_rds_id
}
```

## 💡 **Por que NÃO separamos módulos por ambiente?**

### ❌ **Errado (separar por ambiente):**
```
modules/
├── dev-ec2-infrastructure/
├── dev-ecs-infrastructure/
├── prod-ec2-infrastructure/
└── prod-ecs-infrastructure/
```

### ✅ **Correto (reutilização):**
```
modules/
├── ec2-infrastructure/    # Usado em dev, staging, prod
└── ecs-infrastructure/    # Usado em dev, staging, prod

environments/
├── dev/      # Usa os módulos com config dev
├── staging/  # Usa os módulos com config staging
└── prod/     # Usa os módulos com config prod
```

**Vantagens da reutilização:**
- 🔄 **DRY (Don't Repeat Yourself)** - Código não duplicado
- 🔧 **Manutenção fácil** - Mudança em um lugar afeta todos
- 🧪 **Testes consistentes** - Mesmo código em todos ambientes
- 📦 **Versionamento** - Módulos podem ter versões específicas

## 🎯 **Benefícios da Nossa Arquitetura**

### **1. Economia de Recursos**
- ✅ **Security Groups compartilhados** - EC2 e ECS usam os mesmos
- ✅ **RDS único** - Ambas estratégias conectam no mesmo banco
- ✅ **VPC padrão** - Sem custos adicionais de rede

### **2. Facilidade de Gerenciamento**
- ✅ **Script único** - `create_unified_terraform.sh` cria tudo
- ✅ **Estado unificado** - Um terraform.tfstate para tudo
- ✅ **Outputs interconectados** - ECS usa dados do EC2 automaticamente

### **3. Comparação Fácil**
- ✅ **Mesmo banco** - Ambas estratégias têm os mesmos dados
- ✅ **Mesma rede** - Ambas na mesma VPC e Security Groups
- ✅ **Deploy simultâneo** - Workflows EC2 e ECS rodam juntos

## 🚀 **Próximos Ambientes (Futuro)**

### **Staging:**
```hcl
# environments/staging/main.tf
module "ec2_infrastructure" {
  source = "../../modules/ec2-infrastructure"
  
  # Configurações específicas de staging
  instance_type = "t3.small"        # Maior que dev
  db_instance_class = "db.t4g.small"
  environment = "staging"
}
```

### **Production:**
```hcl
# environments/prod/main.tf
module "ec2_infrastructure" {
  source = "../../modules/ec2-infrastructure"
  
  # Configurações específicas de produção
  instance_type = "t3.medium"       # Ainda maior
  db_instance_class = "db.t4g.medium"
  multi_az = true                   # Alta disponibilidade
  environment = "prod"
}
```

## 📋 **Resumo**

| Aspecto | Modules | Environments |
|---------|---------|--------------|
| **Propósito** | Componentes reutilizáveis | Instâncias específicas |
| **Quantidade** | Poucos (1 por funcionalidade) | Vários (1 por ambiente) |
| **Mudanças** | Afetam todos ambientes | Afetam só o ambiente |
| **Estado** | Sem estado próprio | Cada um tem seu state |
| **Exemplo** | `ec2-infrastructure` | `dev`, `staging`, `prod` |

**🎯 A arquitetura atual é otimizada para desenvolvimento, economia e facilidade de comparação entre estratégias EC2 e ECS!**
