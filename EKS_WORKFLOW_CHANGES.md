# Mudanças no Workflow EKS.yml

## Resumo das Alterações

O arquivo `EKS.yml` foi refatorado para seguir o padrão atual do projeto, removendo a criação de infraestrutura da pipeline e focando apenas no deploy da aplicação.

## Principais Mudanças Realizadas

### 1. **Remoção da Criação de Infraestrutura**
- ❌ Removido: Steps de Terraform que criavam infraestrutura na pipeline
- ❌ Removido: `terraform init`, `terraform plan`, `terraform apply`
- ✅ Adicionado: Validação de cluster EKS existente

### 2. **Estratégia de Variáveis de Ambiente**
```yaml
env:
  AWS_REGION: ${{ vars.AWS_REGION || 'us-east-1' }}
  EKS_CLUSTER_NAME: ${{ vars.EKS_CLUSTER_NAME }}
  DB_HOST: ${{ vars.DB_HOST }}
  DB_PORT: ${{ vars.DB_PORT || '5432' }}
  DB_USER: ${{ vars.DB_USER }}
  DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
  DB_NAME: ${{ vars.DB_NAME }}
```

### 3. **Validação de Conectividade**
- Verifica se `EKS_CLUSTER_NAME` está configurado
- Testa conectividade com `aws sts get-caller-identity`
- Configura kubectl para cluster existente
- Valida acesso com `kubectl cluster-info` e `kubectl get nodes`

### 4. **Gerenciamento de Namespace**
- Usa arquivo `namespace.yaml` do overlay quando disponível
- Fallback para criação dinâmica se arquivo não existir
- Suporte aos ambientes: `dev`, `staging`, `prod`

### 5. **Configuração de Secrets**
- Secrets usando padrão do deployment base existente:
  - `host`, `port`, `username`, `password`, `dbname`
- Remove secret `PORT` (usa valor hardcoded no deployment)

### 6. **Deploy da Aplicação**
- Usa `USERNAME_DOCKER_HUB` (mesmo padrão do Docker.yml)
- Atualiza imagem via Kustomize: `$DOCKER_REGISTRY/go_ci:$IMAGE_TAG`
- Aplica configuração com `kubectl apply -k .`

### 7. **Verificação de Saúde Melhorada**
- Health check via LoadBalancer quando disponível
- Port-forward para teste local (porta 8000 → 8080)
- Logs de debug quando health check falha
- Timeout configurável (30 tentativas com intervalo de 10s)

### 8. **Relatório de Deploy**
- Summary completo com informações do ambiente
- Status de serviços, pods e deployment
- Eventos recentes para troubleshooting
- URLs de acesso quando LoadBalancer disponível

## Variáveis Necessárias por Ambiente

### Variables (Repository/Environment)
```
AWS_REGION=us-east-1
EKS_CLUSTER_NAME=go-api-staging  # ou go-api-prod
DB_HOST=your-rds-endpoint.amazonaws.com
DB_PORT=5432
DB_USER=postgres
DB_NAME=go_api
```

### Secrets (Repository/Environment)
```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
DB_PASSWORD=your-secure-password
USERNAME_DOCKER_HUB=your-dockerhub-username
```

## Pré-requisitos

### 1. **Infraestrutura EKS Criada Separadamente**
- Cluster EKS provisionado via Terraform (módulo `eks-cluster`)
- RDS PostgreSQL configurado
- Security groups e networking configurados

### 2. **Configuração Kubernetes**
- Overlays configurados em `infra/k8s/overlays/{environment}/`
- Arquivos: `namespace.yaml`, `kustomization.yaml`, `deployment-patch.yaml`

### 3. **Imagem Docker**
- Build e push da imagem realizados em step anterior (Docker.yml)
- Tag da imagem passada via `docker_image_tag` input

## Comparação: Estratégia Antiga vs Nova

### EKS-old.yml (Estratégia Antiga)
```yaml
# ❌ Problemas da abordagem antiga:
- run: git clone https://github.com/leollo98/Infra_CI_Kubernetes.git
- run: terraform -chdir=Infra_CI_Kubernetes/env/Homolog apply -auto-approve
- run: kubectl create secret generic dbhost --from-literal=HOST=${{ steps.URL.outputs.stdout }}
- run: kubectl apply -f Infra_CI_Kubernetes/go.yaml
```

### EKS.yml (Nova Estratégia)
```yaml
# ✅ Benefícios da nova abordagem:
- name: Validate EKS Cluster Connection
- name: Create Database Secrets (padrão unificado)
- name: Deploy Application (via Kustomize)
- name: Verify Application Health (com troubleshooting)
```

## Benefícios da Nova Abordagem

1. **🔒 Segurança**: Infraestrutura criada separadamente, não na pipeline
2. **🏗️ Consistência**: Mesmo padrão dos workflows EC2 e ECS  
3. **🔧 Manutenibilidade**: Configuração via overlays e módulos reutilizáveis
4. **🚀 Performance**: Deploy mais rápido (sem criação de infra)
5. **🐛 Debug**: Logs e health checks melhorados
6. **📋 Visibilidade**: Relatórios detalhados de deploy

## Próximos Passos

1. **Criar infraestrutura EKS** via Terraform (ambiente staging/prod)
2. **Configurar variables e secrets** no GitHub
3. **Testar deploy** com a nova pipeline
4. **Documentar processo** de criação de infra separada
