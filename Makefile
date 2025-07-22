# Makefile para projeto Go com Docker

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
	@echo "🔨 Compilando aplicação (estática)..."
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o main .
	@echo "✅ Build concluído!"

build-linux: validate-env
	@echo "🔨 Compilando para Linux (EC2)..."
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags '-w -s -extldflags "-static"' -v -o main main.go
	@echo "✅ Build Linux concluído!"

# === DOCKER - PERFIS ===

.PHONY: dev deploy start-db stop clean
dev: validate-env
	@echo "� Iniciando ambiente de desenvolvimento..."
	docker compose --profile dev up -d
	@echo "✅ Ambiente dev rodando em http://localhost:8000"
	@echo "📊 PgAdmin: http://localhost:54321 (admin@email.com / 123456)"

deploy: build-linux validate-env
	@echo "🚀 Simulando deploy (EC2 + RDS)..."
	docker compose --profile deploy up -d
	@echo "⏳ Aguardando aplicação..."
	@sleep 20
	@echo "✅ Deploy simulado rodando em http://localhost:8080"
	@curl -s http://localhost:8080/alunos > /dev/null && echo "✅ API funcionando!" || echo "⚠️  Verificar logs"

start-db: validate-env
	@echo "� Iniciando apenas PostgreSQL..."
	docker compose up -d postgres

stop:
	@echo "⏹️  Parando todos os serviços..."
	docker compose --profile dev --profile deploy down

clean: stop
	@echo "🧹 Limpeza completa..."
	docker compose --profile dev --profile deploy down -v --rmi local
	@rm -f main
	@sudo rm -rf postgres-data/ 2>/dev/null || true

# === TESTES ===

.PHONY: test lint wait-db
wait-db:
	@echo "⏳ Aguardando PostgreSQL..."
	@for i in $$(seq 1 30); do \
		if docker compose exec -T postgres_ci pg_isready -h localhost > /dev/null 2>&1; then \
			echo "✅ PostgreSQL pronto!"; break; \
		fi; \
		echo "   Tentativa $$i/30..."; sleep 2; \
	done

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

# === UTILITÁRIOS ===

.PHONY: logs status
logs:
	@echo "� Logs dos serviços:"
	docker compose logs -f

status:
	@echo "📊 Status dos serviços:"
	@docker compose ps

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
	@echo "    build-linux        - Compilar para Linux (deploy)"
	@echo ""
	@echo "  🐳 Docker:"
	@echo "    dev                - Ambiente desenvolvimento (http://localhost:8000)"
	@echo "    deploy             - Simulação deploy EC2+RDS (http://localhost:8080)"
	@echo "    start-db           - Apenas PostgreSQL"
	@echo "    stop               - Parar todos os serviços"
	@echo "    clean              - Limpeza completa"
	@echo ""
	@echo "  🧪 Testes:"
	@echo "    test               - Executar testes"
	@echo "    lint               - Executar linting"
	@echo "    ci                 - Pipeline CI completo"
	@echo ""
	@echo "  📊 Utilitários:"
	@echo "    status             - Status dos serviços"
	@echo "    logs               - Ver logs"
	@echo "    help               - Esta ajuda"

# Comando padrão
.DEFAULT_GOAL := help
