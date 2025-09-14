#!/usr/bin/env bash
set -euo pipefail
IMAGE_NAME=${1:-devops-sample-app}
TAG=${2:-latest}
ACCOUNT=${3:-$AWS_ACCOUNT_ID}
REGION=${4:-us-east-1}

# build
docker build -t ${IMAGE_NAME}:${TAG} .

# login & push to ECR
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com

docker tag ${IMAGE_NAME}:${TAG} ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE_NAME}:${TAG}
docker push ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE_NAME}:${TAG}
