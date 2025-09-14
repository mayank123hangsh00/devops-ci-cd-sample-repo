output "ecr_repo_url" { value = aws_ecr_repository.this.repository_url }
output "ecs_cluster_name" { value = aws_ecs_cluster.this.name }
output "ecs_service_name" { value = aws_ecs_service.this.name }
