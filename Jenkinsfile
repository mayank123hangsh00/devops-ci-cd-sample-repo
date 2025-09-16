pipeline {
  agent any

  environment {
    AWS_REGION     = 'ap-south-1'
    AWS_ACCOUNT_ID = '889913637557'
    ECR_REPO       = 'devops-sample-app'
    IMAGE_TAG      = "${env.BUILD_NUMBER ?: 'latest'}"
  }

  triggers {
    // Poll GitHub every 5 mins (or use webhook)
    pollSCM('H/5 * * * *')
  }

  stages {
    stage('Checkout') {
      steps {
        echo "📥 Checking out source code..."
        checkout scm
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          echo "🐳 Building Docker image..."
          sh """
            docker build -t ${ECR_REPO}:${IMAGE_TAG} .
          """
        }
      }
    }

    stage('Push to ECR') {
      steps {
        withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
          script {
            echo "🔑 Logging in to Amazon ECR..."
            sh """
              aws ecr get-login-password --region ${AWS_REGION} | \
              docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

              echo "🏷️ Tagging image..."
              docker tag ${ECR_REPO}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

              echo "📤 Pushing image to ECR..."
              docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
            """
          }
        }
      }
    }

    stage('Deploy to ECS with Terraform') {
      steps {
        withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
          dir('terraform') {
            script {
              sh """
                echo "🔧 Initializing Terraform..."
                terraform init -input=false -no-color

                echo "🚀 Applying Terraform..."
                terraform apply -input=false -auto-approve -no-color \
                  -var "aws_account_id=${AWS_ACCOUNT_ID}" \
                  -var "image_tag=${IMAGE_TAG}" \
                  -var "service_name=${ECR_REPO}" \
                  -var "vpc_id=vpc-0d117a5cf094c9777" \
                  -var 'subnet_ids=["subnet-0966bab78e8556aac","subnet-0bbbc05e87102f723","subnet-02d79f61af69e8c25"]'

                echo "🌐 Fetching ALB DNS name..."
                terraform output -raw alb_dns_name > alb_dns.txt || true

                if [ -f alb_dns.txt ]; then
                  echo "✅ Application deployed successfully!"
                  echo "👉 URL: http://$(cat alb_dns.txt)"
                else
                  echo "⚠️ ALB DNS output not found."
                fi
              """
            }
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'terraform/alb_dns.txt', allowEmptyArchive: true
    }
    success {
      echo "🎉 Pipeline completed successfully!"
    }
    failure {
      echo "❌ Pipeline failed. Check logs above."
    }
  }
}
