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
  description = "Application Load Balancer DNS (null if using existing)"
  value       = try(aws_lb.app_lb[0].dns_name, null)
}

output "alb_target_group_arn" {
  description = "Target Group ARN (null if using existing)"
  value       = try(aws_lb_target_group.app_tg[0].arn, null)
}
