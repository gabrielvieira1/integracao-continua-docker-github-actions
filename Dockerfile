FROM ubuntu:latest

# Instalar dependências essenciais
RUN apt-get update && apt-get install -y \
 ca-certificates \
 curl \
 && rm -rf /var/lib/apt/lists/*

EXPOSE 8000

WORKDIR /app

# Copiar o binário e templates
COPY ./main main
COPY ./templates/ templates

# Dar permissões de execução
RUN chmod +x main

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
 CMD curl -f http://localhost:8000/health || exit 1

CMD [ "./main" ]