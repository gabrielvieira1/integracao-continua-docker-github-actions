# Estratégia de Deploy ECS com Terraform

## 📋 Visão Geral

Esta é a implementação da estratégia de deploy usando **Amazon ECS (Elastic Container Service)** com **Terraform**, substituindo os scripts shell por Infrastructure as Code (IaC).

## 🏗️ Arquitetura

### Componentes Criados pelo Terraform:

1. **ECS Cluster** - `api-go-dev-ecs-cluster`
2. **ECS Service** - `api-go-dev-ecs-svc-app`
3. **ECS Task Definition** - `api-go-dev-taskdef-app`
4. **Application Load Balancer (ALB)** - `api-go-dev-alb-app`
5. **Target Group** - `api-go-dev-tg-app`
6. **Security Groups** (ALB e ECS)
7. **CloudWatch Log Group**
8. **IAM Role** para execução de tasks

### Vantagens da Estratégia ECS:

- ✅ **Escalabilidade automática**
- ✅ **Alta disponibilidade** com múltiplas AZ
- ✅ **Deploy sem downtime** (Blue/Green)
- ✅ **Monitoramento integrado** com CloudWatch
- ✅ **Load balancing** automático
- ✅ **Gerenciamento de containers** pelo AWS

## 📁 Estrutura dos Arquivos

```
infra/
├── terraform/
│   ├── environments/
│   │   └── ecs-dev/                    # Ambiente ECS
│   │       ├── main.tf                 # Configuração principal
│   │       ├── variables.tf            # Variáveis do ambiente
│   │       ├── outputs.tf              # Outputs do ambiente
│   │       └── terraform.tfvars.example # Exemplo de configuração
│   └── modules/
│       └── ecs-infrastructure/         # Módulo reutilizável ECS
│           ├── main.tf                 # Recursos da infraestrutura
│           ├── variables.tf            # Variáveis do módulo
│           └── outputs.tf              # Outputs do módulo
└── scripts/
    ├── create_ecs_terraform.sh         # Script para criar infraestrutura
    └── destroy_ecs_terraform.sh        # Script para destruir infraestrutura
```

## 🚀 Como Usar

### 1. Configuração Inicial

```bash
cd infra/terraform/environments/ecs-dev

# Copiar e configurar variáveis
cp terraform.tfvars.example terraform.tfvars

# Editar com os valores corretos
nano terraform.tfvars
```

**Configurações obrigatórias no `terraform.tfvars`:**
```hcl
db_host     = "api-go-dev-rds-main.XXXXXXX.us-east-1.rds.amazonaws.com"
db_password = "sua_senha_real"
```

### 2. Criar Infraestrutura

```bash
cd infra/scripts
./create_ecs_terraform.sh
```

### 3. Destruir Infraestrutura

```bash
cd infra/scripts
./destroy_ecs_terraform.sh
```

## 🔧 Configuração do GitHub Actions

O workflow `.github/workflows/ECS.yml` foi atualizado para:

1. **Usar ambiente DEV** em vez de PROD
2. **Buscar Task Definition** já criada pelo Terraform
3. **Atualizar apenas a imagem Docker** na task definition
4. **Fazer deploy sem downtime**
5. **Health check melhorado** com retry

### Secrets necessários no GitHub:

- `AWS_ACCESS_KEY_ID_DEV`
- `AWS_SECRET_ACCESS_KEY_DEV` 
- `USERNAME_DOCKER_HUB`
- `DB_PASSWORD_DEV`

## 🌐 URLs de Acesso

Após o deploy, a aplicação estará disponível em:

- **Aplicação**: `http://ALB_DNS_NAME`
- **Health Check**: `http://ALB_DNS_NAME/health`

## 📊 Monitoramento

### CloudWatch Logs
```
Log Group: /ecs/api-go-dev
```

### Métricas ECS
- CPU e memória do container
- Número de tasks em execução
- Status do Load Balancer

## 🔄 Processo de Deploy

1. **GitHub Actions** detecta push/PR
2. **Build e test** da aplicação Go
3. **Build da imagem Docker** e push para Docker Hub
4. **Deploy ECS** atualiza task definition com nova imagem
5. **ECS** faz rolling update sem downtime
6. **Health check** valida se o deploy foi bem-sucedido

## 🆚 Comparação ECS vs EC2

| Aspecto | ECS (Terraform) | EC2 (Scripts) |
|---------|-----------------|---------------|
| **Escalabilidade** | Automática | Manual |
| **Alta Disponibilidade** | Múltiplas AZ | Single instance |
| **Deploy** | Zero downtime | Downtime breve |
| **Monitoramento** | CloudWatch integrado | Manual |
| **Manutenção** | Gerenciado pela AWS | Manual |
| **Custo** | Otimizado | Fixo (instância sempre rodando) |

## 🔧 Troubleshooting

### Problemas Comuns:

1. **Task Definition não encontrada**
   - Certifique-se que a infraestrutura foi criada primeiro

2. **Health Check falhando**
   - Verifique se a aplicação está respondendo na porta 8000
   - Confirme se o endpoint `/health` existe

3. **Deploy falha**
   - Verifique logs no CloudWatch
   - Confirme se as variáveis de ambiente estão corretas

### Comandos Úteis:

```bash
# Ver logs do ECS
aws logs tail /ecs/api-go-dev --follow

# Status do serviço
aws ecs describe-services --cluster api-go-dev-ecs-cluster --services api-go-dev-ecs-svc-app

# Listar tasks
aws ecs list-tasks --cluster api-go-dev-ecs-cluster
```

## 🎯 Próximos Passos

1. **Configurar Auto Scaling** para o ECS Service
2. **Implementar HTTPS** com Certificate Manager
3. **Configurar domínio personalizado**
4. **Implementar Blue/Green deployment** avançado
5. **Adicionar alertas** no CloudWatch

---

✅ **A estratégia ECS com Terraform oferece uma solução robusta, escalável e de fácil manutenção para deploy de containers na AWS!**
