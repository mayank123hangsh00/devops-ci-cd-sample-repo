output "ecr_repo_url" {
  value = local.ecr_repo_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  value = aws_ecs_service.this.name
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS"
  value       = local.alb_dns_name
}
