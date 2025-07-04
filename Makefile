# Makefile para projeto Go com Docker e GitHub Actions

# Variáveis
APP_NAME=go_ci
DOCKER_IMAGE=gabrielvieira/go_ci

# Verificar se arquivo .env existe
.PHONY: check-env
check-env:
	@if [ ! -f .env ]; then \
		echo "❌ Arquivo .env não encontrado!"; \
		echo "📋 Copie o arquivo de exemplo:"; \
		echo "   cp .env.example .env"; \
		echo "✏️  Edite o .env com suas credenciais"; \
		exit 1; \
	fi

# Validar arquivo .env
.PHONY: validate-env
validate-env: check-env
	@echo "🔍 Validando arquivo .env..."
	@if ! grep -q "^DB_USER=" .env; then \
		echo "❌ DB_USER não encontrado no .env"; \
		exit 1; \
	fi
	@if ! grep -q "^DB_PASSWORD=" .env; then \
		echo "❌ DB_PASSWORD não encontrado no .env"; \
		exit 1; \
	fi
	@if ! grep -q "^DB_NAME=" .env; then \
		echo "❌ DB_NAME não encontrado no .env"; \
		exit 1; \
	fi
	@echo "✅ Arquivo .env válido!"

# Mostrar variáveis de ambiente (debug)
.PHONY: show-env
show-env: validate-env
	@echo "🔍 Variáveis de ambiente configuradas:"
	@echo "DB_USER: $$(grep '^DB_USER=' .env | cut -d'=' -f2)"
	@echo "DB_NAME: $$(grep '^DB_NAME=' .env | cut -d'=' -f2)"
	@echo "DB_PASSWORD: ******* (oculta por segurança)"

# Iniciar apenas o banco de dados
.PHONY: start-db
start-db: check-env
	@echo "🐘 Iniciando PostgreSQL..."
	docker compose up -d postgres

# Aguardar PostgreSQL ficar pronto
.PHONY: wait-db
wait-db:
	@echo "⏳ Aguardando PostgreSQL ficar pronto..."
	@for i in $$(seq 1 30); do \
		if docker compose exec -T postgres pg_isready -h localhost > /dev/null 2>&1; then \
			echo "✅ PostgreSQL está pronto!"; \
			break; \
		fi; \
		echo "   Tentativa $$i/30..."; \
		sleep 2; \
	done

# Executar linting
.PHONY: lint
lint:
	@echo "🔍 Executando linting..."
	docker run --rm -itv $(CURDIR):/app -w /app golangci/golangci-lint golangci-lint run controllers/ database/ models/ routes/

# Compilar a aplicação
.PHONY: build
build: validate-env
	@echo "🔨 Compilando aplicação Go..."
	go build -v -o main main.go

# Executar testes (simula ambiente CI)
.PHONY: test
test: start-db wait-db validate-env
	@echo "🧪 Executando testes..."
	@export $$(cat .env | grep -v '^#' | grep -v '^$$' | xargs) && go test -v main_test.go

# Executar testes dentro do container
.PHONY: test-container
test-container: start
	@echo "🧪 Executando testes no container..."
	docker compose exec app go test -v main_test.go

# Iniciar todos os serviços
.PHONY: start
start: check-env
	@echo "🚀 Iniciando todos os serviços..."
	docker compose up -d

# Parar todos os serviços
.PHONY: stop
stop:
	@echo "⏹️  Parando serviços..."
	docker compose down

# Limpar dados do PostgreSQL
.PHONY: clean-db
clean-db: stop
	@echo "🗑️  Removendo dados do PostgreSQL..."
	sudo rm -rf postgres-data/

# Limpar tudo (containers, volumes, imagens)
.PHONY: clean
clean: stop
	@echo "🧹 Limpando containers, volumes e imagens..."
	docker compose down -v --rmi all
	sudo rm -rf postgres-data/

# Simular pipeline CI completo
.PHONY: ci
ci: clean start-db wait-db lint build test
	@echo "✅ Pipeline CI executado com sucesso!"

# Simular pipeline CI com containers
.PHONY: ci-container
ci-container: clean start lint test-container
	@echo "✅ Pipeline CI com containers executado com sucesso!"

# Logs dos serviços
.PHONY: logs
logs:
	docker compose logs -f

# Status dos serviços
.PHONY: status
status:
	docker compose ps

# Setup inicial do projeto
.PHONY: setup
setup:
	@echo "⚙️  Configurando projeto..."
	@if [ ! -f .env ]; then \
		echo "📋 Copiando arquivo .env de exemplo..."; \
		cp .env.local.example .env; \
		echo "✏️  IMPORTANTE: Edite o arquivo .env com suas credenciais"; \
	fi
	@echo "✅ Setup concluído!"

# Ajuda
.PHONY: help
help:
	@echo "📖 Comandos disponíveis:"
	@echo ""
	@echo "  🔧 Setup e Configuração:"
	@echo "    setup          - Configuração inicial do projeto"
	@echo "    check-env      - Verificar se .env existe"
	@echo "    validate-env   - Validar conteúdo do .env"
	@echo "    show-env       - Mostrar variáveis configuradas"
	@echo ""
	@echo "  🐳 Docker:"
	@echo "    start          - Iniciar todos os serviços"
	@echo "    start-db       - Iniciar apenas PostgreSQL"
	@echo "    stop           - Parar serviços"
	@echo "    status         - Status dos serviços"
	@echo "    logs           - Ver logs dos serviços"
	@echo ""
	@echo "  🔨 Build e Testes:"
	@echo "    build          - Compilar aplicação"
	@echo "    test           - Executar testes (simula CI)"
	@echo "    test-container - Executar testes no container"
	@echo "    lint           - Executar linting"
	@echo ""
	@echo "  🚀 CI/CD:"
	@echo "    ci             - Simular pipeline CI completo"
	@echo "    ci-container   - Simular CI com containers"
	@echo ""
	@echo "  🧹 Limpeza:"
	@echo "    clean-db       - Remover dados do PostgreSQL"
	@echo "    clean          - Limpar tudo (containers, volumes, imagens)"