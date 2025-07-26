# Infraestrutura EC2 para API Go

Esta documentação descreve como usar a infraestrutura Terraform para deploy em EC2, baseada nos scripts shell originais.

## 📋 Recursos Criados

### Security Groups
- **api-go-dev-sg-app**: Security Group para a aplicação
  - Porta 8000: API Go
  - Porta 22: SSH
  - Acesso total ao RDS

- **api-go-dev-sg-db**: Security Group para o banco RDS
  - Porta 5432: PostgreSQL (apenas do SG da aplicação)
  - Auto-referência para comunicação interna

### EC2 Instance
- **api-go-dev-ec2-bastion**: Instância EC2 para a aplicação
  - Tipo: t2.micro
  - AMI: Amazon Linux 2023
  - IP público habilitado
  - **Sem user_data**: Deploy gerenciado via GitHub Actions SSH

### RDS Database
- **api-go-dev-rds-main**: Banco PostgreSQL
  - Engine: PostgreSQL 13.21
  - Classe: db.t4g.micro
  - Storage: 20GB (GP2)
  - Backup: 1 dia de retenção
  - Performance Insights habilitado

### Networking
- **api-go-dev-sng-private**: DB Subnet Group
  - Usa todas as subnets da VPC default

### **Fluxo de Deploy Simplificado**
```
1. 🏗️  Terraform cria EC2 + RDS (infraestrutura)
2. 🚀 GitHub Actions faz SSH na instância
3. 📦 Deploy do binário Go compilado
4. ⚙️  Configura env vars dinamicamente
5. 🔄 Restart da aplicação
```

## 🚀 Como Usar

### Pré-requisitos
```bash
# Terraform instalado
terraform --version

# AWS CLI configurado
aws configure

# Verificar credenciais
aws sts get-caller-identity
```

### 1. Criar Infraestrutura
```bash
# Executar script automatizado
./infra/scripts/create_ec2_terraform.sh

# OU manualmente
cd infra/terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### 2. Obter Informações de Conexão
```bash
cd infra/terraform/environments/dev
terraform output

# Para ver detalhes de conexão sensíveis
terraform output connection_details
```

### 3. Deploy da Aplicação
O workflow `.github/workflows/EC2.yml` automaticamente:
1. Busca o IP público da instância EC2
2. Busca detalhes de conexão do RDS
3. Faz deploy do binário via SSH
4. Configura variáveis de ambiente
5. Inicia a aplicação

### 4. Destruir Infraestrutura
```bash
# Executar script automatizado
./infra/scripts/destroy_ec2_terraform.sh

# OU manualmente
cd infra/terraform/environments/dev
terraform destroy
```

## 🔧 Configurações

### Variáveis de Ambiente (Terraform)
```hcl
# infra/terraform/environments/dev/variables.tf
variable "db_password" {
  description = "Database master password"
  type        = string
  default     = "123456789"
  sensitive   = true
}
```

### Secrets do GitHub Actions
Configure os seguintes secrets no GitHub:

**Para ambiente DEV:**
- `AWS_ACCESS_KEY_ID_DEV`
- `AWS_SECRET_ACCESS_KEY_DEV`
- `DB_PASSWORD_DEV` = `123456789`
- `SSH_PRIVATE_KEY`
- `REMOTE_USER`
- `USERNAME_DOCKER_HUB`

## 📊 Outputs

Após a criação, o Terraform fornece:
```
ec2_instance_id = "i-xxxxxxxxx"
ec2_public_ip = "xx.xx.xx.xx"
ec2_private_ip = "10.0.x.x"
rds_endpoint = "api-go-dev-rds-main.xxxxxxxxx.us-east-1.rds.amazonaws.com"
rds_port = 5432
security_group_api_id = "sg-xxxxxxxxx"
security_group_rds_id = "sg-xxxxxxxxx"
```

## 🔒 Segurança

### RDS
- Acesso apenas via Security Group da aplicação
- Não possui IP público
- Comunicação criptografada
- Storage criptografado

### EC2
- SSH apenas com chave privada
- Security Group restritivo
- User data script para configuração segura

## 🚀 Deploy Workflow

O arquivo `.github/workflows/EC2.yml` está configurado para:
1. Usar ambiente `DEV`
2. Buscar recursos dinamicamente pelos nomes/tags
3. Usar secrets específicos do ambiente DEV
4. Fazer deploy automatizado do binário Go

### Ativação do Deploy EC2
No arquivo `go.yml`, o deploy EC2 está ativo:
```yaml
Deploy_EC2:
  needs: docker
  uses: ./.github/workflows/EC2.yml
  secrets: inherit
```

## 🆚 Comparação com Scripts Shell

| Aspecto | Scripts Shell | Terraform |
|---------|---------------|-----------|
| **Idempotência** | Manual | Automática |
| **State Management** | Nenhum | Arquivo de estado |
| **Rollback** | Manual | `terraform destroy` |
| **Recursos Órfãos** | Possível | Prevenidos |
| **Documentação** | Scripts | Código declarativo |
| **Reutilização** | Limitada | Módulos reutilizáveis |

## 🔧 Troubleshooting

### Erro: Security Group já existe
```bash
# Verificar recursos existentes
aws ec2 describe-security-groups --group-names api-go-dev-sg-app
```

### Erro: RDS já existe
```bash
# Verificar instâncias RDS existentes
aws rds describe-db-instances --db-instance-identifier api-go-dev-rds-main
```

### Limpeza manual (se necessário)
```bash
# Remover recursos órfãos criados pelos scripts shell
aws ec2 delete-security-group --group-id sg-xxxxxxxxx
aws rds delete-db-instance --db-instance-identifier api-go-dev-rds-main --skip-final-snapshot
```

## 🎯 Próximos Passos

1. **Monitoramento**: Adicionar CloudWatch metrics
2. **Backup**: Configurar backup automatizado
3. **Scaling**: Preparar para Auto Scaling Groups
4. **Load Balancer**: Adicionar ALB para alta disponibilidade
5. **HTTPS**: Configurar certificados SSL/TLS
