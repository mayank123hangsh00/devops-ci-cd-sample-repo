# --- Fetch Default VPC & Subnets ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- ECR Repository ---
resource "aws_ecr_repository" "this" {
  name = "devops-sample-app"

  lifecycle {
    prevent_destroy = true   # Prevent accidental deletion
  }
}

# --- ECS Cluster ---
resource "aws_ecs_cluster" "this" {
  name = "${var.service_name}-cluster"
}

# --- CloudWatch Logs ---
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 14
}

# --- IAM Role for ECS Task Execution ---
resource "aws_iam_role" "ecs_task_exec" {
  name               = "ecsTaskExecutionRole-${var.service_name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
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
  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- Security Group ---
resource "aws_security_group" "sg" {
  name        = "${var.service_name}-sg"
  description = "Allow HTTP inbound"
  vpc_id      = data.aws_vpc.default.id   # ✅ use default VPC

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

  lifecycle {
    prevent_destroy = true   # ✅ Keep SG across pipeline runs
  }
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn

  container_definitions = templatefile("${path.module}/ecs-task-def.json", {
    image        = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.service_name}:${var.image_tag}"
    service_name = var.service_name
    region       = var.region
  })
}

# --- ECS Service ---
resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids   # ✅ use default subnets
    security_groups = [aws_security_group.sg.id]
    assign_public_ip = true
  }
}
