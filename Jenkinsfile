pipeline {
  agent any

  environment {
    AWS_REGION = 'ap-south-1'    
    AWS_ACCOUNT_ID = '889913637557'
    ECR_REPO = "${env.ECR_REPO ?: 'devops-sample-app'}"
    IMAGE_TAG = "${env.BUILD_NUMBER ?: 'local'}"
  }

  triggers {
    // GitHub webhook triggers this job
    // Also support polling as fallback
    pollSCM('H/5 * * * *')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Test') {
      steps {
        sh 'npm ci'
        sh 'npm test || true'
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
        }
      }
    }

    stage('Push to ECR') {
      steps {
        withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
          sh '''
            set -e
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com
            docker tag ${ECR_REPO}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
            docker push ${AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
          '''
        }
      }
    }

    stage('Deploy to ECS') {
      steps {
        withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
          sh '''
            set -e
            cd terraform
            terraform init -input=false
            terraform apply -input=false -auto-approve -var "image_tag=${IMAGE_TAG}" -var "aws_account_id=${AWS_ACCOUNT_ID}"
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

