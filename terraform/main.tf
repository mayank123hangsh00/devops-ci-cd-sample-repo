provider "aws" {
  region = "ap-south-1"
}

# VPC, Subnets, Security Groups
resource "aws_vpc" "main" {
  id = "vpc-0d117a5cf094c9777"
}

resource "aws_subnet" "subnet1" {
  id = "subnet-0966bab78e8556aac"
}

resource "aws_subnet" "subnet2" {
  id = "subnet-0bbbc05e87102f723"
}

resource "aws_subnet" "subnet3" {
  id = "subnet-02d79f61af69e8c25"
}

resource "aws_security_group" "ecs_sg" {
  id = "sg-08513895b5f933feb"
}

# ECR Repository
resource "aws_ecr_repository" "app" {
  name = "devops-sample-app"
}

# ECS Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = "devops-sample-app-cluster"
}

# IAM Role for ECS task execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "devops-sample-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "devops-sample-app"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "devops-sample-app-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [
      aws_subnet.subnet1.id,
      aws_subnet.subnet2.id,
      aws_subnet.subnet3.id
    ]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "devops-sample-app"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.front_end]
}

# ALB
resource "aws_lb" "app_alb" {
  name               = "devops-sample-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = [
    aws_subnet.subnet1.id,
    aws_subnet.subnet2.id,
    aws_subnet.subnet3.id
  ]
}

resource "aws_lb_target_group" "app_tg" {
  name     = "devops-sample-app-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}
