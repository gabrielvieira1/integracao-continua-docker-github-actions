# Makefile para projeto Go com Docker e GitHub Actions
# Versão simplificada e organizada

APP_NAME=go_ci
DOCKER_IMAGE=gabrielvieira/go_ci

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
		echo "✅ Arquivo .env criado com configurações padrão"; \
	fi
	@echo "✅ Setup concluído!"

# === BUILD E DESENVOLVIMENTO ===

.PHONY: build build-linux
build: validate-env
	@echo "🔨 Compilando aplicação..."
	go build -v -o main main.go
	@echo "✅ Build concluído!"

build-linux: validate-env
	@echo "🔨 Compilando para Linux (EC2)..."
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags '-w -s -extldflags "-static"' -v -o main main.go
	@echo "✅ Build Linux concluído!"

# === DOCKER ===

.PHONY: start-db wait-db start stop clean
start-db: validate-env
	@echo "🐘 Iniciando PostgreSQL..."
	docker compose up -d postgres

wait-db:
	@echo "⏳ Aguardando PostgreSQL..."
	@for i in $$(seq 1 30); do \
		if docker compose exec -T postgres pg_isready -h localhost > /dev/null 2>&1; then \
			echo "✅ PostgreSQL pronto!"; break; \
		fi; \
		echo "   Tentativa $$i/30..."; sleep 2; \
	done

start: validate-env
	@echo "🚀 Iniciando todos os serviços..."
	docker compose up -d

stop:
	@echo "⏹️  Parando serviços..."
	docker compose down

clean: stop
	@echo "🧹 Limpeza completa..."
	docker compose down -v --rmi local
	sudo rm -rf postgres-data/ 2>/dev/null || true

# === TESTES ===

.PHONY: test lint
test: start-db wait-db validate-env
	@echo "🧪 Executando testes..."
	@export $$(cat .env | grep -v '^#' | grep -v '^$$' | xargs) && go test -v main_test.go

lint:
	@echo "🔍 Executando linting..."
	docker run --rm -v $(CURDIR):/app -w /app golangci/golangci-lint golangci-lint run controllers/ database/ models/ routes/

# === PIPELINE CI/CD ===

.PHONY: ci
ci: clean build start-db wait-db lint test
	@echo "✅ Pipeline CI executado com sucesso!"

# === TESTES EC2 COM DOCKER ===

.PHONY: start-ec2-test deploy-ec2-docker check-ec2-docker clean-ec2-test
start-ec2-test: validate-env
	@echo "🐳 Iniciando ambiente EC2 simulado..."
	docker-compose -f docker-compose.vm-test.yml up -d
	@sleep 10
	@echo "✅ Ambiente pronto!"

deploy-ec2-docker: build-linux start-ec2-test
	@echo "🚀 Deploy EC2 simulado..."
	docker cp main vm_test_ec2:/home/gabriel/
	docker cp templates vm_test_ec2:/home/gabriel/ 2>/dev/null || true
	docker cp assets vm_test_ec2:/home/gabriel/ 2>/dev/null || true
	
	@export $$(cat .env | grep -v '^#' | xargs) && \
	docker exec vm_test_ec2 bash -c "\
		cd /home/gabriel && \
		export HOST=postgres && \
		export DB_USER=$$DB_USER && \
		export DB_PASSWORD=$$DB_PASSWORD && \
		export DB_NAME=$$DB_NAME && \
		export DB_PORT=5432 && \
		export PORT=8000 && \
		pkill -f './main' 2>/dev/null || true && \
		chmod +x main && \
		nohup ./main > app.log 2>&1 & \
		sleep 3 && \
		pgrep -f './main' > /dev/null && echo '✅ Aplicação rodando!' \
	"

check-ec2-docker:
	@echo "🔍 Verificando aplicação..."
	@docker exec vm_test_ec2 ps aux | grep './main' | grep -v grep || echo "⚠️  App não está rodando"
	@curl -s http://localhost:8000/ > /dev/null && echo "✅ App responde!" || echo "❌ App não responde"

clean-ec2-test:
	@echo "🧹 Limpando ambiente EC2..."
	docker-compose -f docker-compose.vm-test.yml down -v
	docker image rm vm-test-image 2>/dev/null || true

# === UTILITÁRIOS ===

.PHONY: logs shell-ec2 status help
logs:
	docker compose logs -f

shell-ec2:
	@echo "🔗 Conectando no container EC2..."
	docker exec -it vm_test_ec2 bash

status:
	@echo "📊 Status dos serviços:"
	docker compose ps
	docker ps | grep vm_test_ec2 || echo "Container EC2: ❌ Parado"

help:
	@echo "📖 Comandos disponíveis:"
	@echo ""
	@echo "  🔧 Setup:"
	@echo "    setup              - Configuração inicial"
	@echo "    validate-env       - Validar .env"
	@echo "    show-env           - Mostrar configurações"
	@echo ""
	@echo "  🔨 Build:"
	@echo "    build              - Compilar aplicação"
	@echo "    build-linux        - Compilar para Linux"
	@echo ""
	@echo "  🐳 Docker Local:"
	@echo "    start-db           - Iniciar PostgreSQL"
	@echo "    start              - Iniciar todos serviços"
	@echo "    stop               - Parar serviços"
	@echo "    clean              - Limpeza completa"
	@echo ""
	@echo "  🧪 Testes:"
	@echo "    test               - Executar testes"
	@echo "    lint               - Executar linting"
	@echo "    ci                 - Pipeline CI completo"
	@echo ""
	@echo "  🖥️  EC2 Simulado:"
	@echo "    start-ec2-test     - Iniciar ambiente EC2"
	@echo "    deploy-ec2-docker  - Deploy no EC2 simulado"
	@echo "    check-ec2-docker   - Verificar deploy"
	@echo "    shell-ec2          - Shell no container"
	@echo "    clean-ec2-test     - Limpar ambiente EC2"
	@echo ""
	@echo "  📊 Utilitários:"
	@echo "    status             - Status dos serviços"
	@echo "    logs               - Ver logs"
	@echo "    help               - Esta ajuda"
	@echo ""
	@echo "  🧪 Testes de Deployment:"
	@echo "    test-deploy        - Testar estratégia de deployment"

# Comando padrão
.DEFAULT_GOAL := help

# === TESTES DE DEPLOYMENT ===

.PHONY: test-deploy
test-deploy:
	@echo "🧪 Testando estratégia de deployment..."
	./test-deployment-strategy.sh
