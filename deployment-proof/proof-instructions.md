# Deployment Proof Instructions

1. After successful deploy, note the ALB DNS name or public endpoint and add it to `deployment-proof/URL.txt`.
2. Take screenshots of:
   - Jenkins pipeline run with stages (Build, Dockerize, Push, Deploy) showing success.
   - AWS ECR repository showing pushed image and tag.
   - AWS ECS service showing running task (and logs visible in CloudWatch).
   - Deployed app response in browser (or curl output).
3. Add screenshots into `deployment-proof/example-screenshots/`.
4. Include a text file `deployment-proof/URL.txt` with the public URL.
