provider "aws" {
  region = var.region
}

# ---------------------------
# Security Group
# ---------------------------
resource "aws_security_group" "sg" {
  name        = "${var.service_name}-sg"
  description = "Allow HTTP inbound"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# ECR Repo
# ---------------------------
resource "aws_ecr_repository" "this" {
  name = var.service_name
}

# ---------------------------
# ECS Cluster
# ---------------------------
resource "aws_ecs_cluster" "this" {
  name = var.service_name
}

# ---------------------------
# Task Definition
# ---------------------------
resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = templatefile("${path.module}/ecs-task-def.json", {
    service_name = var.service_name
    image        = "${aws_ecr_repository.this.repository_url}:${var.image_tag}"
    region       = var.region
  })
}

# ---------------------------
# ALB + Target Group (optional)
# ---------------------------
resource "aws_lb" "app_lb" {
  count              = var.use_existing ? 0 : 1
  name               = "${var.service_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "app_tg" {
  count       = var.use_existing ? 0 : 1
  name        = "${var.service_name}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "app_listener" {
  count             = var.use_existing ? 0 : 1
  load_balancer_arn = aws_lb.app_lb[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg[0].arn
  }
}

# ---------------------------
# ECS Service
# ---------------------------
resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.sg.id]
    assign_public_ip = true
  }

  dynamic "load_balancer" {
    for_each = var.use_existing ? [] : [1]
    content {
      target_group_arn = aws_lb_target_group.app_tg[0].arn
      container_name   = var.service_name
      container_port   = 8080
    }
  }
}
