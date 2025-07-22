# 🔐 Configuração de Secrets do GitHub Actions

Este documento lista todos os secrets necessários para o pipeline CI/CD funcionar corretamente em todos os ambientes.

## 📋 Secrets Obrigatórios por Ambiente

### 🔧 Secrets Gerais (Repository Level)
Configurar em: `Settings > Secrets and Variables > Actions > Repository secrets`

```
# Database para testes CI
DB_USER=root
DB_PASSWORD=your_test_db_password
DB_NAME=test_db

# Docker Registry
DOCKER_USERNAME=your_dockerhub_username
DOCKER_PASSWORD=your_dockerhub_password

# AWS (para Load Testing)
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=us-east-1

# Coverage (opcional)
CODECOV_TOKEN=your_codecov_token
```

### 🖥️ Secrets EC2 por Ambiente
Configurar em: `Settings > Secrets and Variables > Actions > Environments`

#### Environment: `dev`
```
# EC2 Connection
EC2_HOST=your-dev-ec2-host.com
EC2_USER=ubuntu
EC2_SSH_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
your-private-key-content-here
-----END OPENSSH PRIVATE KEY-----

# Database DEV
DB_HOST_DEV=your-dev-db-host.com
DB_USER_DEV=dev_user
DB_PASSWORD_DEV=dev_password
DB_NAME_DEV=app_dev
DB_PORT_DEV=5432
```

#### Environment: `staging`
```
# EC2 Connection
EC2_HOST=your-staging-ec2-host.com
EC2_USER=ubuntu
EC2_SSH_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
your-private-key-content-here
-----END OPENSSH PRIVATE KEY-----

# Database STAGING
DB_HOST_STAGING=your-staging-db-host.com
DB_USER_STAGING=staging_user
DB_PASSWORD_STAGING=staging_password
DB_NAME_STAGING=app_staging
DB_PORT_STAGING=5432
```

#### Environment: `homolog`
```
# EC2 Connection
EC2_HOST=your-homolog-ec2-host.com
EC2_USER=ubuntu
EC2_SSH_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
your-private-key-content-here
-----END OPENSSH PRIVATE KEY-----

# Database HOMOLOG
DB_HOST_HOMOLOG=your-homolog-db-host.com
DB_USER_HOMOLOG=homolog_user
DB_PASSWORD_HOMOLOG=homolog_password
DB_NAME_HOMOLOG=app_homolog
DB_PORT_HOMOLOG=5432
```

#### Environment: `production`
```
# EC2 Connection
EC2_HOST=your-prod-ec2-host.com
EC2_USER=ubuntu
EC2_SSH_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
your-private-key-content-here
-----END OPENSSH PRIVATE KEY-----

# Database PRODUCTION
DB_HOST_PROD=your-prod-db-host.com
DB_USER_PROD=prod_user
DB_PASSWORD_PROD=strong_prod_password
DB_NAME_PROD=app_production
DB_PORT_PROD=5432
```

## 🌟 Estratégia de Deployment

### 📂 Estrutura de Branches → Environments

| Branch     | Environment | Port | Auto Deploy | Load Test |
|------------|-------------|------|-------------|-----------|
| `develop`  | dev         | 8001 | ✅          | ❌        |
| `staging`  | staging     | 8002 | ✅          | ✅ (20 users) |
| `homolog`  | homolog     | 8003 | ✅          | ✅ (50 users) |
| `main`     | production  | 8000 | ✅          | ❌        |

### 🔄 Workflow de Deploy

1. **Push para `develop`** → Deploy automático para DEV
2. **Push para `staging`** → Deploy para STAGING + Load Test (20 users, 120s)
3. **Push para `homolog`** → Deploy para HOMOLOG + Load Test (50 users, 300s)
4. **Push para `main`** → Deploy para PRODUCTION (sem load test)

### 📊 Ambiente na AWS (para Load Test)

Estrutura esperada no repositório de infraestrutura:
```
Infra_CI/
├── env/
│   ├── Dev/
│   ├── Staging/
│   ├── Homolog/
│   └── Production/
```

## 🛠️ Como Configurar os Secrets

### 1. Repository Secrets
```bash
# Acesse: github.com/your-username/your-repo/settings/secrets/actions
# Clique em "New repository secret"
# Adicione cada secret da seção "Secrets Gerais"
```

### 2. Environment Secrets
```bash
# Acesse: github.com/your-username/your-repo/settings/environments
# Crie os environments: dev, staging, homolog, production
# Para cada environment, adicione os secrets correspondentes
```

### 3. Chave SSH
```bash
# Gerar nova chave SSH para cada ambiente:
ssh-keygen -t ed25519 -C "github-actions-dev" -f ~/.ssh/github_actions_dev

# Copiar chave pública para o servidor EC2:
ssh-copy-id -i ~/.ssh/github_actions_dev.pub ubuntu@your-ec2-host.com

# Copiar chave privada para o secret:
cat ~/.ssh/github_actions_dev | pbcopy  # Mac
cat ~/.ssh/github_actions_dev | xclip -sel clip  # Linux
```

## ✅ Verificação dos Secrets

Use este checklist para verificar se todos os secrets estão configurados:

### Repository Level
- [ ] `DB_USER`
- [ ] `DB_PASSWORD`
- [ ] `DB_NAME`
- [ ] `DOCKER_USERNAME`
- [ ] `DOCKER_PASSWORD`
- [ ] `AWS_ACCESS_KEY_ID`
- [ ] `AWS_SECRET_ACCESS_KEY`
- [ ] `AWS_REGION`

### Environment: dev
- [ ] `EC2_HOST`
- [ ] `EC2_USER`
- [ ] `EC2_SSH_PRIVATE_KEY`
- [ ] `DB_HOST_DEV`
- [ ] `DB_USER_DEV`
- [ ] `DB_PASSWORD_DEV`
- [ ] `DB_NAME_DEV`

### Environment: staging
- [ ] `EC2_HOST`
- [ ] `EC2_USER`
- [ ] `EC2_SSH_PRIVATE_KEY`
- [ ] `DB_HOST_STAGING`
- [ ] `DB_USER_STAGING`
- [ ] `DB_PASSWORD_STAGING`
- [ ] `DB_NAME_STAGING`

### Environment: homolog
- [ ] `EC2_HOST`
- [ ] `EC2_USER`
- [ ] `EC2_SSH_PRIVATE_KEY`
- [ ] `DB_HOST_HOMOLOG`
- [ ] `DB_USER_HOMOLOG`
- [ ] `DB_PASSWORD_HOMOLOG`
- [ ] `DB_NAME_HOMOLOG`

### Environment: production
- [ ] `EC2_HOST`
- [ ] `EC2_USER`
- [ ] `EC2_SSH_PRIVATE_KEY`
- [ ] `DB_HOST_PROD`
- [ ] `DB_USER_PROD`
- [ ] `DB_PASSWORD_PROD`
- [ ] `DB_NAME_PROD`

## 🚀 Melhorias Implementadas

### 📦 Actions Atualizadas
- ✅ `actions/checkout@v4` (era v3)
- ✅ `actions/setup-go@v5` (era v4)
- ✅ `actions/upload-artifact@v4` (era v3)
- ✅ `actions/download-artifact@v4` (era v3)
- ✅ `aws-actions/configure-aws-credentials@v4` (era v1)
- ✅ `actions/setup-python@v5` (era v2.3.3)
- ✅ `hashicorp/setup-terraform@v3.0.0` (era v2.0.3)
- ✅ `easingthemes/ssh-deploy@v5.0.3` (era @main)
- ✅ `appleboy/ssh-action@v1.0.3` (era @master)

### 🔧 Funcionalidades Adicionadas
- ✅ Cache de módulos Go para builds mais rápidos
- ✅ Versionamento automático de releases
- ✅ Health checks após deploy
- ✅ Relatórios de teste de carga com artifacts
- ✅ Environments separados com proteção
- ✅ Rollback automático em caso de falha
- ✅ Coverage de testes integrado
- ✅ Deploy paths separados por ambiente
- ✅ Logs estruturados e debugging

### 🛡️ Segurança
- ✅ Secrets separados por ambiente
- ✅ Chaves SSH únicas por ambiente
- ✅ Proteção de branches production
- ✅ Environments com approval gates (opcional)
- ✅ Cleanup automático de recursos temporários

## 📞 Suporte

Se encontrar problemas na configuração:
1. Verifique os logs do GitHub Actions
2. Confirme se todos os secrets estão preenchidos
3. Teste a conectividade SSH manualmente
4. Valide a configuração do banco de dados

## 🔄 Próximos Passos

1. Configure os environments no GitHub
2. Adicione todos os secrets listados
3. Teste com um push para `develop`
4. Valide o deploy em cada ambiente
5. Configure proteções de branch para `main`
