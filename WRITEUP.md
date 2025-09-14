# WRITEUP

## Tools used
- GitHub (source control)
- Jenkins (CI/CD orchestration)
- Docker (containerization)
- AWS ECR + ECS (registry + runtime)
- Terraform (IaC)
- CloudWatch (monitoring & logs)

## Challenges
1. IAM & permissions: needed a role that allowed ECS tasks to pull images from ECR and push metrics to CloudWatch.
2. Networking: deciding whether to create a new VPC or use existing. Simpler to use existing public subnets for quick demo.

## Solutions
- Used Task Execution Role with `AmazonECSTaskExecutionRolePolicy` attached.
- Provided terraform variables so the user can plug in existing VPC/subnet ids.

## Improvements if more time
- Add Blue/Green or Canary deployments using CodeDeploy or ECS deployment controller.
- Add autoscaling policies for ECS service.
- Add CI secrets management via HashiCorp Vault or AWS Secrets Manager.
- Add HTTPS using ACM & ALB.
