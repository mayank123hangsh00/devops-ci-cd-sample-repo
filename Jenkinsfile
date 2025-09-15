pipeline {
  agent any

  environment {
    AWS_REGION     = 'ap-south-1'
    AWS_ACCOUNT_ID = '889913637557'
    ECR_REPO       = "${env.ECR_REPO ?: 'devops-sample-app'}"
    IMAGE_TAG      = "${env.BUILD_NUMBER ?: 'local'}"
  }

  triggers {
    pollSCM('H/5 * * * *')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          sh """
            echo "Building Docker image..."
            docker build -t ${ECR_REPO}:${IMAGE_TAG} .
          """
        }
      }
    }

    stage('Push to ECR') {
      steps {
        withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
          script {
            sh """
              echo "Logging in to Amazon ECR..."
              aws ecr get-login-password --region ${AWS_REGION} | \
              docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

              echo "Tagging image..."
              docker tag ${ECR_REPO}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

              echo "Pushing image..."
              docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
            """
          }
        }
      }
    }

    stage('Deploy to ECS with Terraform') {
      steps {
        withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
          sh '''
            set -e
            cd terraform

            echo "🔑 Exporting AWS creds for Terraform..."
            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
            export AWS_DEFAULT_REGION=$AWS_REGION

            echo "🚀 Running terraform init..."
            terraform init -input=false -no-color

            echo "⚡ Running terraform apply..."
            terraform apply -input=false -auto-approve -no-color \
              -var "aws_account_id=${AWS_ACCOUNT_ID}" \
              -var "image_tag=${IMAGE_TAG}" \
              -var "service_name=devops-sample-app" \
              -var "vpc_id=vpc-0d117a5cf094c9777" \
              -var 'subnet_ids=["subnet-0966bab78e8556aac","subnet-0bbbc05e87102f723","subnet-02d79f61af69e8c25"]'

            echo "🌐 Fetching ALB DNS name..."
            terraform output -raw alb_dns_name > alb_dns.txt || true

            echo "✅ Application deployed successfully!"
            if [ -f alb_dns.txt ]; then
              echo "👉 URL: http://$(cat alb_dns.txt)"
            fi

            cd ..
          '''
        }
      }
    }
  }
}
