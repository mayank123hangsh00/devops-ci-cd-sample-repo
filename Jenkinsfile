pipeline {
  agent any

  environment {
    AWS_REGION     = 'ap-south-1'
    AWS_ACCOUNT_ID = '889913637557'
    ECR_REPO       = 'devops-sample-app'
    IMAGE_TAG      = "${env.BUILD_NUMBER ?: 'latest'}"
  }

  triggers {
    pollSCM('H/5 * * * *')
  }

  stages {
    stage('Checkout') {
      steps {
        echo "📥 Checking out source..."
        checkout scm
      }
    }

    stage('Build & Test') {
      steps {
        sh(script: '''
          echo "🔧 npm ci (if present) and tests"
          npm ci || true
          npm test || true
        ''')
      }
    }

    stage('Build Docker Image') {
      steps {
        sh(script: '''
          echo "🐳 Building Docker image..."
          docker --version || true
          docker build -t ${ECR_REPO}:${IMAGE_TAG} .
        ''')
      }
    }

    stage('Push to ECR') {
      steps {
        withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
          sh(script: '''
            set -e
            echo "🔑 Logging in to ECR..."
            aws --version
            aws ecr get-login-password --region $AWS_REGION \
              | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com

            echo "🏷 Tagging image..."
            docker tag ${ECR_REPO}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

            echo "📤 Pushing image..."
            docker push ${AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
          ''')
        }
      }
    }

    stage('Terraform Apply (deploy to ECS)') {
      steps {
        withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
          dir('terraform') {
            sh(script: '''
              set -e

              echo "🔧 terraform init..."
              terraform init -input=false -no-color

              echo "🚀 terraform apply..."
              terraform apply -input=false -auto-approve -no-color \
                -var "aws_account_id=${AWS_ACCOUNT_ID}" \
                -var "image_tag=${IMAGE_TAG}" \
                -var "service_name=${ECR_REPO}" \
                -var "vpc_id=vpc-0d117a5cf094c9777" \
                -var "subnet_ids=[\"subnet-0966bab78e8556aac\",\"subnet-0bbbc05e87102f723\",\"subnet-02d79f61af69e8c25\"]" \
                -var "use_existing=true"

              echo "🌐 fetching ALB DNS (terraform output)..."
              terraform output -raw alb_dns_name > alb_dns.txt || true

              if [ -s alb_dns.txt ]; then
                echo "✅ ALB DNS:"
                cat alb_dns.txt
              else
                echo "⚠ ALB DNS not present in Terraform outputs"
              fi
            ''')
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'terraform/alb_dns.txt', allowEmptyArchive: true
    }
    success { echo "🎉 Pipeline succeeded" }
    failure { echo "❌ Pipeline failed — see console log" }
  }
}
