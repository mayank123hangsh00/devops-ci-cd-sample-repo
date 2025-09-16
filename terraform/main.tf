provider "aws" {
  region = "ap-south-1"
}

# -------------------------------
# ECR Repository
# -------------------------------
resource "aws_ecr_repository" "this" {
  name = "devops-sample-app"
}

# -------------------------------
# ECS Cluster
# -------------------------------
resource "aws_ecs_cluster" "this" {
  name = "devops-sample-app-cluster"
}

# -------------------------------
# IAM Role for ECS Task Execution
# -------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

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
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -------------------------------
# Load Balancer (ALB)
# -------------------------------
resource "aws_lb" "app_alb" {
  name               = "devops-sample-app-alb"
  load_balancer_type = "application"
  security_groups    = ["sg-08513895b5f933feb"]
  subnets            = [
    "subnet-0966bab78e8556aac",
    "subnet-0bbbc05e87102f723",
    "subnet-02d79f61af69e8c25"
  ]
}

resource "aws_lb_target_group" "app_tg" {
  name        = "devops-sample-app-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "vpc-0d117a5cf094c9777"
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# -------------------------------
# ECS Task Definition
# -------------------------------
resource "aws_ecs_task_definition" "this" {
  family                   = "devops-sample-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "devops-sample-app"
      image     = "${aws_ecr_repository.this.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/devops-sample-app"
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# -------------------------------
# ECS Service
# -------------------------------
resource "aws_ecs_service" "this" {
  name            = "devops-sample-app-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [
      "subnet-0966bab78e8556aac",
      "subnet-0bbbc05e87102f723",
      "subnet-02d79f61af69e8c25"
    ]
    security_groups = ["sg-08513895b5f933feb"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "devops-sample-app"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.app_listener]
}

# -------------------------------
# Outputs
# -------------------------------
output "ecr_repo_url" {
  value = aws_ecr_repository.this.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  value = aws_ecs_service.this.name
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS"
  value       = aws_lb.app_alb.dns_name
}
