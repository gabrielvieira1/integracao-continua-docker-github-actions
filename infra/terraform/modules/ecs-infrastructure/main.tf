# Application Load Balancer (usa o mesmo SG da API)
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb-app"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.existing_api_sg_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb-app"
  })
}

# Target Group
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-${var.environment}-tg-app"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tg-app"
  })
}

# Load Balancer Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.container_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = var.tags
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-ecs-cluster"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-cluster"
  })
}

# IAM Role para ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-task-execution-role"
  })
}

# Attach da policy padrão para ECS Task Execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition (SEM CloudWatch Logs)
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.environment}-taskdef-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "Go"
      image     = var.docker_image
      cpu       = 0
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
          name          = "go-${var.container_port}-tcp"
          appProtocol   = "http"
        }
      ]

      environment = [
        {
          name  = "HOST"
          value = var.db_host
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "PORT"
          value = tostring(var.container_port)
        },
        {
          name  = "DB_PORT"
          value = tostring(var.db_port)
        },
        {
          name  = "DB_USER"
          value = var.db_username
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        }
      ]

      # SEM logConfiguration - logs desabilitados para evitar problemas de conectividade
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-taskdef-app"
  })
}

# ECS Service (usa o mesmo Security Group da API)
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-${var.environment}-ecs-svc-app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 0
  }

  platform_version = "LATEST"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.existing_api_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "Go"
    container_port   = var.container_port
  }

  health_check_grace_period_seconds = 60

  depends_on = [
    aws_lb_listener.main,
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-svc-app"
  })
}
