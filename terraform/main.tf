provider "aws" {
  region = "ap-south-1"
}

# ECS Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = "devops-sample-cluster"
}

# Security Group
resource "aws_security_group" "app_sg" {
  name        = "devops-sample-sg"
  description = "Allow HTTP traffic"
  vpc_id      = "vpc-0d117a5cf094c9777"

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
}

# Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "devops-sample-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets            = [
    "subnet-0966bab78e8556aac",
    "subnet-0bbbc05e87102f723",
    "subnet-02d79f61af69e8c25"
  ]
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "devops-sample-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0d117a5cf094c9777"
}

# Listener
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ✅ Outputs
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "alb_url" {
  description = "Full URL to access the application via ALB"
  value       = "http://${aws_lb.app_alb.dns_name}"
}
