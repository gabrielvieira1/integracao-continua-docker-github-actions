# AI Agent Instructions for Go API Multi-Deployment Project

## Project Overview

This is a Go REST API project demonstrating three different AWS deployment strategies:

- **EC2**: Direct deployment with RDS PostgreSQL
- **ECS**: Containerized deployment with Fargate
- **EKS**: Kubernetes orchestration

The application is a simple student management API using Gin framework with GORM and PostgreSQL.

## Code Architecture & Patterns

### Application Structure

```
/                           # Go application root
├── main.go                 # Entry point - imports database and routes
├── main_test.go           # Test file
├── controllers/           # HTTP handlers (Gin controllers)
├── models/               # GORM models with validation
├── routes/               # Route definitions
├── database/             # Database connection logic
├── templates/            # HTML templates for web interface
├── assets/               # Static CSS files
└── infra/                # Infrastructure as Code
```

### Go Module Structure

- **Package Name**: `github.com/guilhermeonrails/api-go-gin`
- **Import Style**: Use full package path for imports
- **Dependencies**: Gin, GORM, PostgreSQL driver, validator.v2

### Key Code Patterns

#### Database Connection Pattern

```go
// Always use environment variables with fallbacks
host := os.Getenv("HOST")
if host == "" {
    host = "localhost"
}

// Connection string format
stringDeConexao := "host="+host+" user="+user+" password="+password+" dbname="+dbname+" port="+dbport+" sslmode=disable"
```

#### Controller Pattern

```go
// Standard HTTP response format
c.JSON(200, gin.H{
    "status": "success",
    "data": data,
})

// Error handling pattern
if err != nil {
    c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
    return
}
```

#### Model Validation Pattern

```go
type Aluno struct {
    gorm.Model
    Nome string `json:"nome" validate:"nonzero"`
    RG   string `json:"rg" validate:"len=9, regexp=^[0-9]*$"`
    CPF  string `json:"cpf" validate:"len=11, regexp=^[0-9]*$"`
}
```

## Infrastructure Architecture

### Terraform Organization

- **Path**: `infra/terraform/modules/`
- **Modules**: `ec2-infrastructure/`, `ecs-infrastructure/`, `eks-cluster/`
- **Environments**: `infra/terraform/environments/dev/`, `prod/`

### Key Infrastructure Patterns

#### Terraform Resource Naming

```terraform
name = "${var.project_name}-${var.environment}-${resource_type}"
# Example: "go-api-dev-sg-app"
```

#### Security Group Strategy

- Separate SGs for application (`sg-app`) and database (`sg-db`)
- Rules defined separately to avoid dependency cycles
- Port 8000 for Go application (not 8080)

#### Environment Variables Pattern

```yaml
# GitHub Actions
DB_USER: ${{ vars.DB_USER_DEV }}
DB_PASSWORD: ${{ secrets.DB_PASSWORD_DEV }}
DB_NAME: ${{ vars.DB_NAME_DEV }}
```

### Kubernetes Configuration

- **Path**: `infra/k8s/`
- **Structure**: `base/` with Kustomize overlays
- **Deployment**: 3 replicas, rolling updates
- **Port**: Application uses 8000, K8s exposes 8080

## GitHub Actions Workflows

### Workflow Structure

1. **go.yml**: Core testing with matrix (Go 1.20, 1.21)
2. **Docker.yml**: Container building and registry push
3. **EC2.yml**: Direct AWS deployment
4. **ECS.yml**: Container orchestration
5. **EKS.yml**: Kubernetes deployment
6. **LoadTest.yml**: Performance validation

### Environment Strategy

- **DEV**: Used for testing and validation
- **PROD**: Production deployments
- Secrets vs Variables: Passwords in secrets, config in variables

## Docker & Containerization

### Dockerfile Pattern

```dockerfile
FROM ubuntu:latest
EXPOSE 8000
WORKDIR /app
COPY ./main main        # Pre-built binary
COPY ./templates/ templates
RUN chmod +x main
HEALTHCHECK --interval=30s CMD curl -f http://localhost:8000/health
```

### Build Process

1. Go build creates `main` binary
2. Docker copies binary (not source)
3. Multi-stage builds not used (simple approach)

## Common Development Tasks

### Building & Testing

```bash
# Local build
go build -o main .

# Run tests with database
docker-compose up -d postgres
go test -v ./...

# Clean build
make clean && make build
```

### Infrastructure Operations

```bash
# Deploy to specific environment
cd infra/terraform/environments/dev
terraform init
terraform plan
terraform apply

# Cleanup with task definition handling
./infra/scripts/destroy_unified_terraform.sh
```

### Port Configuration

- **Application**: Always 8000 (Go gin server)
- **Database**: 5432 (PostgreSQL)
- **Load Balancer**: 80/443 → 8000
- **Kubernetes**: 8080 external → 8000 internal

## API Endpoints & Conventions

### Standard Routes

```go
r.GET("/health", controllers.HealthCheck)      # Always implement health check
r.GET("/alunos", controllers.TodosAlunos)      # List all
r.GET("/alunos/:id", controllers.BuscarAlunoPorID)  # Get by ID
r.POST("/alunos", controllers.CriarNovoAluno)       # Create
r.PATCH("/alunos/:id", controllers.EditarAluno)     # Update
r.DELETE("/alunos/:id", controllers.DeletarAluno)   # Delete
r.GET("/alunos/cpf/:cpf", controllers.BuscaAlunoPorCPF)  # Search
```

### Health Check Response

```json
{
  "status": "healthy",
  "message": "API is running",
  "database": "connected",
  "version": "1.0.0"
}
```

## Environment Variables Reference

### Required for Application

- `HOST`: Database host (default: localhost)
- `DB_USER`: Database username
- `DB_PASSWORD`: Database password
- `DB_NAME`: Database name
- `DB_PORT`: Database port (default: 5432)
- `PORT`: Application port (default: 8000)

### AWS Deployment Variables

- `AWS_REGION`: Target AWS region
- `ECR_REPOSITORY`: Container registry
- `ECS_CLUSTER`: ECS cluster name
- `EKS_CLUSTER_NAME`: Kubernetes cluster

## Troubleshooting Patterns

### Common Issues

1. **Port Conflicts**: Application uses 8000, not 8080
2. **Database Connection**: Check environment variables and security groups
3. **Task Definitions**: AWS ECS tasks become INACTIVE, not deleted
4. **Health Checks**: Simplified version for debugging (database check commented)

### Debug Commands

```bash
# Check application logs
docker logs <container_id>

# Verify database connection
go run main.go  # Check logs for connection status

# Test health endpoint
curl http://localhost:8000/health
```

## Development Guidelines

### Code Style

- Use Portuguese for domain terms (`Aluno`, `ConectaComBancoDeDados`)
- English for technical terms (`HealthCheck`, `HandleRequest`)
- Consistent error handling with JSON responses
- Environment variable validation with fallbacks

### Testing Strategy

- Unit tests in `main_test.go`
- Integration tests with Docker Compose
- Load testing with dedicated workflow
- Health checks in all deployment scenarios

### Infrastructure Changes

- Always use Terraform for resource management
- Test in DEV environment first
- Update all three deployment strategies when changing core infrastructure
- Use unified cleanup scripts for consistency

## AI Assistant Context

When working on this project:

1. **Port Numbers**: Always use 8000 for the Go application
2. **Package Imports**: Use the full package path `github.com/guilhermeonrails/api-go-gin/...`
3. **Environment Strategy**: DEV for testing, secrets for sensitive data
4. **Multi-Deployment**: Consider impact on EC2, ECS, and EKS when making changes
5. **Database**: PostgreSQL with GORM, always include connection validation
6. **Container Strategy**: Pre-built binaries, not source compilation in Docker
7. **Infrastructure**: Terraform-first approach, AWS CLI only for cleanup edge cases

This project demonstrates production-ready Go API deployment across multiple AWS services with proper CI/CD, making it an excellent reference for cloud-native Go applications.
