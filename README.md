# DevOps CI/CD Sample: Node.js -> Docker -> AWS ECS (Fargate) via Jenkins

**What this repo contains**

- Example Node.js app (simple HTTP server).
- Dockerfile with best-practices (multi-stage).
- Jenkinsfile (Declarative pipeline) that builds, tests, builds Docker image, pushes to ECR, and runs Terraform to deploy to ECS Fargate.
- Terraform to create ECR, ECS cluster, task definition, Fargate service, ALB, IAM roles (minimal, requires you to supply VPC/subnet info or extend to create networking).
- Docs and WRITEUP describing architecture and choices.

## Architecture

Included: `docs/architecture.mmd` (Mermaid). Diagram: GitHub -> Jenkins (webhook) -> ECR -> ECS (Fargate) behind ALB. Monitoring: CloudWatch metrics & logs.

## Branching strategy

- `main` - production-ready, deployable.
- `dev` - integration and CI validation; Jenkins runs on pushes to `dev` and PR merges to `main` trigger production pipeline.

Suggested workflow:

```bash
git checkout -b dev
# work & commit
git push origin dev
# create PR to merge dev -> main when ready
```

## Prerequisites

- AWS account with permissions to create IAM, ECR, ECS, ALB, CloudWatch, VPC resources.
- Jenkins server (can be on an EC2 instance or local) with plugins: GitHub, Pipeline, Docker Pipeline, Amazon ECR, Credentials, GitHub Branch Source.
- Terraform v1.0+
- Docker installed on Jenkins agent or use Jenkins agent with Docker.
- AWS CLI configured for your user (for local testing).

## Quick start (high level)

1. Fork this repo to your GitHub account and clone.
2. Create branches `dev` and `main`.
3. Configure AWS credentials in Jenkins as `aws-creds` (IAM user with ECR/ECS permissions) and DockerHub credentials if using DockerHub.
4. In GitHub repo settings -> Webhooks -> Add Jenkins webhook: `http://<JENKINS_HOST>/github-webhook/`.
5. Configure Terraform variables (see `terraform/variables.tf` comments). Run `terraform init` and `terraform apply` to create infra OR let Jenkins run Terraform in the pipeline (recommended to manage infra via IaC pipeline stage).
6. Push code to `dev` to trigger pipeline.

## Files of interest

- `Dockerfile` uses multi-stage build to keep final image small.
- `Jenkinsfile` contains declarative pipeline stages for build/test/dockerize/push/deploy.
- `terraform/` contains example Terraform to create ECR, ECS resources and CloudWatch log group. You must supply VPC/subnet IDs or extend terraform to create networking.

## Monitoring & Logging

- CloudWatch Logs: ECS Task definitions send logs to `/ecs/<service-name>` Log Group.
- CloudWatch Metrics: ECS service & ALB metrics visible in CloudWatch console.

To view logs: AWS Console -> CloudWatch -> Logs -> Log groups -> `/ecs/<service-name>`.

## Deployment proof

Place either: public URL of your ALB/Cloud Run endpoint or screenshots in `deployment-proof/`.

## Notes & possible improvements

- For production: use private subnets, NAT Gateways, HTTPS (ACM), ALB listeners, autoscaling, Blue/Green or Canary deployment patterns.

