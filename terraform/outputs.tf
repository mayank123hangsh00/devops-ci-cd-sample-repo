output "ecs_cluster_name" {
  value = aws_ecs_cluster.app_cluster.name
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "alb_url" {
  description = "Full URL to access the application via ALB"
  value       = "http://${aws_lb.app_alb.dns_name}"
}

output "alb_target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.app_tg.arn
}


