# integracao-continua-docker-github-actions



# Configuração de GitHub Secrets

⚠️ **IMPORTANTE PARA SEGURANÇA**: Este projeto foi configurado para NÃO ter credenciais hardcoded no código. Todas as variáveis sensíveis devem ser configuradas via GitHub Secrets.

## Como configurar os Secrets

1. Vá para o seu repositório no GitHub
2. Clique em **Settings** → **Secrets and variables** → **Actions**
3. Clique em **New repository secret**
4. Adicione os seguintes secrets:

### Secrets para Docker Hub

- `USERNAME_DOCKER_HUB`: Seu username do Docker Hub
- `PASSWORD_DOCKER_HUB`: Seu password ou token do Docker Hub

### Secrets para Banco de Dados

- `DB_USER`: Usuário do banco de dados PostgreSQL
- `DB_PASSWORD`: Senha do banco de dados PostgreSQL
- `DB_NAME`: Nome do banco de dados PostgreSQL

## Environment (Opcional)

Para usar environments no GitHub Actions, vá em **Settings** → **Environments** e crie um environment chamado `production`.

## Como executar localmente

⚠️ **IMPORTANTE**: As variáveis de ambiente são **obrigatórias**. Sem elas, o docker-compose falhará.

### Opção 1: Arquivo .env (Recomendado)
1. Copie o arquivo `.env.example` para `.env`:
   ```bash
   cp .env.example .env
   ```

2. **Edite o arquivo `.env` com suas credenciais reais**:
   ```bash
   # Exemplo - substitua pelos seus valores
   DB_USER=meu_usuario_real
   DB_PASSWORD=minha_senha_real
   DB_NAME=meu_banco_real
   ```

3. Execute com docker-compose:
   ```bash
   docker-compose up -d
   ```

### Opção 2: Variáveis de ambiente diretas
```bash
DB_USER=seu_usuario DB_PASSWORD=sua_senha DB_NAME=seu_banco docker-compose up -d
```

### Para desenvolvimento local apenas:
Se você quiser usar credenciais simples apenas para desenvolvimento:
```bash
cp .env.local.example .env
docker-compose up -d
```

## Como executar a imagem de produção

```bash
docker run -e HOST=localhost -e PORT=5432 -e DB_USER=seu_usuario -e DB_PASSWORD=sua_senha -e DB_NAME=seu_banco -p 8000:8000 gabrielvieira/go_ci:latest
```

## Segurança

✅ **O que está seguro:**

- Todas as credenciais usam GitHub Secrets
- Arquivo `.env` está no `.gitignore`
- Dockerfile não contém informações sensíveis
- Workflows do GitHub Actions usam secrets para credenciais
- **Sem valores padrão sensíveis**: docker-compose falha se as variáveis não estiverem definidas

❌ **NUNCA faça:**

- Commite arquivos `.env` com credenciais reais
- Use credenciais hardcoded nos workflows
- Exponha senhas em logs ou documentação
- **Use credenciais reais como valores padrão (fallback)**

⚠️ **IMPORTANTE**: Este projeto foi configurado para **falhar** se as variáveis de ambiente não estiverem definidas, impedindo o uso acidental de credenciais padrão inseguras.



# 🚀 Guia do Makefile

Este Makefile fornece comandos para testar e executar o projeto localmente, simulando o ambiente de CI/CD.

## 📋 Setup Inicial

```bash
# Configuração inicial (cria .env se não existir)
make setup

# Verificar se .env existe
make check-env

# Ver todos os comandos disponíveis
make help
```

## 🧪 Testando o Projeto

### Teste Completo (Simula GitHub Actions)
```bash
# Simula exatamente o que acontece no CI
make ci
```

Este comando executa:
1. ✅ Limpa ambiente anterior
2. 🐘 Inicia PostgreSQL
3. ⏳ Aguarda banco ficar pronto
4. 🔍 Executa linting
5. 🔨 Compila aplicação
6. 🧪 Executa testes

### Testes Individuais
```bash
# Apenas testes
make test

# Testes no container
make test-container

# Apenas linting
make lint

# Apenas build
make build
```

## 🐳 Gerenciamento Docker

```bash
# Iniciar todos os serviços
make start

# Iniciar apenas PostgreSQL
make start-db

# Parar serviços
make stop

# Ver status
make status

# Ver logs
make logs
```

## 🧹 Limpeza

```bash
# Limpar dados do PostgreSQL
make clean-db

# Limpar tudo (containers, volumes, imagens)
make clean
```

## 🔧 Troubleshooting

### Erro: "Arquivo .env não encontrado"
```bash
make setup
# Depois edite o .env com suas credenciais
```

### PostgreSQL não conecta
```bash
# Verificar se está rodando
make status

# Ver logs
make logs

# Reiniciar
make stop && make start-db
```

### Testes falhando
```bash
# Verificar se banco está pronto
make wait-db

# Executar apenas os testes
make test
```

## 🎯 Comandos Principais para Desenvolvimento

```bash
# Setup inicial
make setup

# Desenvolvimento diário
make ci  # Executa pipeline completo

# Debug
make logs  # Ver logs dos serviços
```
