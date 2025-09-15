pipeline {
  agent any

  environment {
    AWS_REGION     = 'ap-south-1'
    AWS_ACCOUNT_ID = '889913637557'
    ECR_REPO       = "devops-sample-app"
    IMAGE_TAG      = "${env.BUILD_NUMBER ?: 'local'}"
  }

  triggers {
    // Trigger via GitHub webhook or fallback polling
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

    stage('Deploy to ECS') {
      steps {
        withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
          sh '''
            set -e
            cd terraform

            echo "Running terraform init..."
            terraform init -input=false

            echo "Running terraform apply..."
            terraform apply -input=false -auto-approve \
              -var "image_tag=${IMAGE_TAG}" \
              -var "aws_account_id=${AWS_ACCOUNT_ID}" \
              -var "region=${AWS_REGION}" \
              -var "service_name=devops-sample-app"

            cd ..
          '''
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'logs/**', allowEmptyArchive: true
    }
    success {
      echo 'Pipeline succeeded.'
    }
    failure {
      echo 'Pipeline failed.'
    }
  }
}
