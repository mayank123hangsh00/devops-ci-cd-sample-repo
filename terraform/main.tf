locals {
  sg_name  = "${var.service_name}-sg"
  lb_name  = "${var.service_name}-alb"
  tg_name  = "${var.service_name}-tg"
}

# --- Data blocks (only used when use_existing = true) ---
data "aws_ecr_repository" "existing" {
  count = var.use_existing ? 1 : 0
  name  = var.service_name
}

data "aws_cloudwatch_log_group" "existing" {
  count = var.use_existing ? 1 : 0
  name  = "/ecs/${var.service_name}"
}

data "aws_iam_role" "existing" {
  count = var.use_existing ? 1 : 0
  name  = "ecsTaskExecutionRole-${var.service_name}"
}

data "aws_security_group" "existing" {
  count = var.use_existing ? 1 : 0
  filter {
    name   = "group-name"
    values = [local.sg_name]
  }
  # ensure vpc_id matches so the lookup is unambiguous
  vpc_id = var.vpc_id
}

data "aws_lb" "existing" {
  count = var.use_existing ? 1 : 0
  name  = local.lb_name
}

data "aws_lb_target_group" "existing" {
  count = var.use_existing ? 1 : 0
  name  = local.tg_name
}

# --- Create resources only when use_existing = false ---
resource "aws_ecr_repository" "this" {
  count = var.use_existing ? 0 : 1
  name  = var.service_name

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [name]
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  count             = var.use_existing ? 0 : 1
  name              = "/ecs/${var.service_name}"
  retention_in_days = 14

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [name, retention_in_days]
  }
}

resource "aws_iam_role" "ecs_task_exec" {
  count               = var.use_existing ? 0 : 1
  name                = "ecsTaskExecutionRole-${var.service_name}"
  assume_role_policy  = data.aws_iam_policy_document.ecs_assume_role.json

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [name]
  }
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  count      = var.use_existing ? 0 : 1
  role       = aws_iam_role.ecs_task_exec[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "sg" {
  count       = var.use_existing ? 0 : 1
  name        = local.sg_name
  description = "Allow HTTP inbound"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # also open port 80 for the ALB if created
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [name, vpc_id]
  }
}

# ALB / Target Group / Listener: create only when use_existing = false
resource "aws_lb" "app_lb" {
  count               = var.use_existing ? 0 : 1
  name                = local.lb_name
  internal            = false
  load_balancer_type  = "application"
  security_groups     = [ var.use_existing ? data.aws_security_group.existing[0].id : aws_security_group.sg[0].id ]
  subnets             = var.subnet_ids
}

resource "aws_lb_target_group" "app_tg" {
  count       = var.use_existing ? 0 : 1
  name        = local.tg_name
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

# Task Definition: always created (it references role id/arn via locals)
resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.use_existing ? data.aws_iam_role.existing[0].arn : aws_iam_role.ecs_task_exec[0].arn

  container_definitions = templatefile("${path.module}/ecs-task-def.json", {
    image        = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.service_name}:${var.image_tag}"
    service_name = var.service_name
    region       = var.region
  })
}

# ECS Service behind ALB (always created)
resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [ var.use_existing ? data.aws_security_group.existing[0].id : aws_security_group.sg[0].id ]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.use_existing ? data.aws_lb_target_group.existing[0].arn : aws_lb_target_group.app_tg[0].arn
    container_name   = var.service_name
    container_port   = 8080
  }

  depends_on = var.use_existing ? [] : [aws_lb_listener.app_listener]
}

# ECS Cluster (always created)
resource "aws_ecs_cluster" "this" {
  name = "${var.service_name}-cluster"
}

# Locals to pick correct DNS/URLs for outputs
locals {
  ecr_repo_url = var.use_existing ? data.aws_ecr_repository.existing[0].repository_url : aws_ecr_repository.this[0].repository_url
  alb_dns_name = var.use_existing ? (length(data.aws_lb.existing) > 0 ? data.aws_lb.existing[0].dns_name : "") : (length(aws_lb.app_lb) > 0 ? aws_lb.app_lb[0].dns_name : "")
}
