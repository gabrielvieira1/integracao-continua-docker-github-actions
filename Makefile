# Makefile para projeto Go com Docker

APP_NAME=go_ci
DOCKER_IMAGE=bielvieira/go_ci

# === CONFIGURAÇÃO E VALIDAÇÃO ===

.PHONY: check-env validate-env show-env
check-env:
	@if [ ! -f .env ]; then \
		echo "❌ Arquivo .env não encontrado! Execute: make setup"; \
		exit 1; \
	fi

validate-env: check-env
	@echo "🔍 Validando arquivo .env..."
	@for var in DB_USER DB_PASSWORD DB_NAME DB_PORT HOST PORT; do \
		if ! grep -q "^$$var=" .env; then \
			echo "❌ $$var não encontrado no .env"; \
			exit 1; \
		fi; \
	done
	@echo "✅ Arquivo .env válido!"

show-env: validate-env
	@echo "🔍 Variáveis configuradas:"
	@grep -E "^(DB_USER|DB_NAME|DB_PORT|HOST|PORT)=" .env | sed 's/DB_PASSWORD=.*/DB_PASSWORD=***/'

# === SETUP INICIAL ===

.PHONY: setup
setup:
	@echo "⚙️  Configuração inicial do projeto..."
	@if [ ! -f .env ]; then \
		echo "DB_USER=root" > .env; \
		echo "DB_PASSWORD=root" >> .env; \
		echo "DB_NAME=root" >> .env; \
		echo "DB_PORT=5432" >> .env; \
		echo "HOST=localhost" >> .env; \
		echo "PORT=8000" >> .env; \
		echo "✅ Arquivo .env criado com configurações locais (user=root)"; \
	fi
	@echo "✅ Setup concluído!"

# === BUILD ===

.PHONY: build build-linux
build: validate-env
	@echo "🔨 Compilando aplicação (estática)..."
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o main .
	@echo "✅ Build concluído!"

build-linux: validate-env
	@echo "🔨 Compilando para Linux (compatível com deploy)..."
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags '-w -s -extldflags "-static"' -v -o main main.go
	@echo "✅ Build Linux concluído!"

# === DOCKER - DESENVOLVIMENTO E DEPLOY ===

.PHONY: dev deploy start-db stop clean
dev: build validate-env
	@echo "🚀 Iniciando ambiente de desenvolvimento..."
	docker compose --profile dev up -d
	@echo "✅ Ambiente dev rodando em http://localhost:8000"
	@echo "📊 PgAdmin: http://localhost:54321 (admin@email.com / 123456)"

deploy: build-linux validate-env
	@echo "🚀 Simulando deploy (EC2 + RDS)..."
	docker compose --profile deploy up -d
	@echo "⏳ Aguardando aplicação inicializar..."
	@sleep 20
	@echo "✅ Deploy simulado rodando em http://localhost:8080"
	@if curl -s http://localhost:8080/health > /dev/null; then \
		echo "✅ API funcionando!"; \
	else \
		echo "⚠️  Verificar logs: make logs-deploy"; \
	fi

start-db: validate-env
	@echo "🐘 Iniciando apenas PostgreSQL..."
	docker compose up -d postgres

stop:
	@echo "⏹️  Parando todos os serviços..."
	docker compose --profile dev --profile deploy down

clean: stop
	@echo "🧹 Limpeza completa..."
	docker compose --profile dev --profile deploy down -v --rmi local
	@rm -f main
	@sudo rm -rf postgres-data/ 2>/dev/null || true

# === KUBERNETES LOCAL (SIMULAÇÃO EKS) ===

.PHONY: k8s-setup k8s-deploy k8s-test k8s-clean k8s-status k8s-logs
k8s-setup: build validate-env
	@echo "🚀 Configurando Kubernetes local (simulação EKS)..."
	
	# 1. Criar cluster kind se não existir
	@if ! kind get clusters | grep -q "go-api-local"; then \
		echo "📦 Criando cluster kind..."; \
		echo "kind: Cluster" > /tmp/kind-config.yaml; \
		echo "apiVersion: kind.x-k8s.io/v1alpha4" >> /tmp/kind-config.yaml; \
		echo "nodes:" >> /tmp/kind-config.yaml; \
		echo "- role: control-plane" >> /tmp/kind-config.yaml; \
		echo "  extraPortMappings:" >> /tmp/kind-config.yaml; \
		echo "  - containerPort: 30080" >> /tmp/kind-config.yaml; \
		echo "    hostPort: 30080" >> /tmp/kind-config.yaml; \
		echo "    protocol: TCP" >> /tmp/kind-config.yaml; \
		kind create cluster --name go-api-local --config /tmp/kind-config.yaml; \
		rm -f /tmp/kind-config.yaml; \
	else \
		echo "✅ Cluster kind já existe"; \
	fi
	
	# 2. Configurar kubectl para o cluster local
	@kubectl config use-context kind-go-api-local > /dev/null
	
	# 3. Aguardar cluster estar pronto
	@echo "⏳ Aguardando cluster estar pronto..."
	@kubectl wait --for=condition=Ready nodes --all --timeout=60s > /dev/null
	
	# 4. Iniciar PostgreSQL local para simular RDS
	@echo "🐘 Iniciando PostgreSQL local (simular RDS)..."
	@docker compose up -d postgres > /dev/null
	@$(MAKE) wait-db
	
	@echo "✅ Kubernetes local configurado!"
	@echo "🔗 Cluster: kind-go-api-local"
	@echo "🐘 PostgreSQL: localhost:5432"

k8s-deploy: k8s-setup
	@echo "🚀 Fazendo deploy no Kubernetes local..."
	
	# 1. Baixar e carregar imagem do Docker Hub
	@echo "� Baixando e carregando imagem bielvieira/go_ci:40..."
	@docker pull bielvieira/go_ci:40 > /dev/null
	@kind load docker-image bielvieira/go_ci:40 --name go-api-local > /dev/null
	
	# 2. Deploy usando kustomize (configuração local separada)
	@echo "📝 Aplicando manifests com kustomize (local)..."
	@kustomize build infra/k8s-local | kubectl apply -f - > /dev/null
	
	# 3. Aguardar deployment
	@echo "⏳ Aguardando deployment..."
	@kubectl wait --for=condition=available --timeout=120s deployment/go-api -n go-api-dev > /dev/null
	
	@echo "✅ Deploy Kubernetes concluído!"
	@echo "🔗 Acesso: http://localhost:30080"

k8s-test: 
	@echo "🧪 Testando aplicação Kubernetes..."
	@echo "Health Check:"
	@if curl -f http://localhost:30080/health 2>/dev/null; then \
		echo "✅ Kubernetes deploy funcionando!"; \
	else \
		echo "❌ Kubernetes deploy com problemas"; \
		echo "📋 Verificar: make k8s-logs"; \
	fi

k8s-status:
	@echo "📊 Status do Kubernetes:"
	@kubectl get pods -n go-api-dev
	@echo ""
	@kubectl get svc -n go-api-dev

k8s-logs:
	@echo "📋 Logs da aplicação:"
	@kubectl logs -l app=go-api -n go-api-dev --tail=20

k8s-clean:
	@echo "🧹 Limpando ambiente Kubernetes..."
	@kubectl delete namespace go-api-dev --ignore-not-found > /dev/null 2>&1 || true
	@kind delete cluster --name go-api-local > /dev/null 2>&1 || true
	@echo "✅ Kubernetes limpo!"

# === TESTES E LOGS ===

.PHONY: test logs-dev logs-deploy wait-db health
wait-db:
	@echo "⏳ Aguardando PostgreSQL..."
	@for i in $$(seq 1 30); do \
		if docker ps --format "table {{.Names}}\t{{.Status}}" | grep postgres_ci | grep -q "Up"; then \
			echo "✅ PostgreSQL pronto!"; break; \
		fi; \
		echo "   Tentativa $$i/30..."; sleep 2; \
	done

test: start-db wait-db validate-env
	@echo "🧪 Executando testes..."
	@export $$(cat .env | grep -v '^#' | grep -v '^$$' | xargs) && go test -v main_test.go

logs-dev:
	@echo "📋 Logs do ambiente dev:"
	docker compose logs go_app_dev

logs-deploy:
	@echo "📋 Logs do ambiente deploy:"
	docker compose logs go_app_deploy

health:
	@echo "🏥 Testando health checks..."
	@echo "Dev (8000):"
	@curl -f http://localhost:8000/health 2>/dev/null && echo "✅ OK" || echo "❌ FAIL"
	@echo "Deploy (8080):"
	@curl -f http://localhost:8080/health 2>/dev/null && echo "✅ OK" || echo "❌ FAIL"
	@echo "Kubernetes (30080):"
	@curl -f http://localhost:30080/health 2>/dev/null && echo "✅ OK" || echo "❌ FAIL"

# === PIPELINE CI/CD ===

.PHONY: ci
ci: clean build start-db wait-db test
	@echo "✅ Pipeline CI executado com sucesso!"

# === HELP ===

.PHONY: help
help:
	@echo "🚀 Comandos disponíveis:"
	@echo ""
	@echo "📋 Configuração:"
	@echo "    setup              - Configuração inicial"
	@echo "    check-env          - Verificar .env"
	@echo "    show-env           - Mostrar configurações"
	@echo ""
	@echo "🔨 Build:"
	@echo "    build              - Compilar aplicação"
	@echo "    build-linux        - Compilar para Linux"
	@echo ""
	@echo "🐳 Docker:"
	@echo "    dev                - Ambiente desenvolvimento"
	@echo "    deploy             - Simular deploy EC2"
	@echo "    start-db           - Apenas PostgreSQL"
	@echo "    stop               - Parar serviços"
	@echo "    clean              - Limpeza completa"
	@echo ""
	@echo "☸️  Kubernetes:"
	@echo "    k8s-setup          - Configurar cluster local"
	@echo "    k8s-deploy         - Deploy completo"
	@echo "    k8s-test           - Testar aplicação"
	@echo "    k8s-status         - Status dos pods"
	@echo "    k8s-logs           - Logs da aplicação"
	@echo "    k8s-clean          - Limpar ambiente K8s"
	@echo ""
	@echo "🧪 Testes:"
	@echo "    test               - Executar testes"
	@echo "    health             - Health checks"
	@echo "    logs-dev           - Logs ambiente dev"
	@echo "    logs-deploy        - Logs ambiente deploy"
	@echo "    ci                 - Pipeline completo"
