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
