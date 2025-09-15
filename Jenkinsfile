pipeline {
  agent any

  environment {
    AWS_REGION = 'ap-south-1'    
    AWS_ACCOUNT_ID = '889913637557'
    IMAGE_TAG = "${env.BUILD_NUMBER ?: 'local'}"
    VPC_ID = 'vpc-0d117a5cf094c9777'
    SUBNET_IDS = '["subnet-0966bab78e8556aac","subnet-0bbbc05e87102f723","subnet-02d79f61af69e8c25"]'
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

    stage('Build & Test') {
      steps {
        sh 'npm ci'
        sh 'npm test || true'
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          sh "docker build -t devops-sample-app:${IMAGE_TAG} ."
        }
      }
    }

    stage('Push to ECR') {
      steps {
        withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
          sh '''
            set -e
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com
            docker tag devops-sample-app:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com/devops-sample-app:${IMAGE_TAG}
            docker push ${AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com/devops-sample-app:${IMAGE_TAG}
          '''
        }
      }
    }

    stage('Deploy to ECS') {
      steps {
        withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
          sh """
            set -e
            cd terraform
            terraform init -input=false
            terraform apply -input=false -auto-approve \
              -var "image_tag=${IMAGE_TAG}" \
              -var "aws_account_id=${AWS_ACCOUNT_ID}" \
              -var "vpc_id=${VPC_ID}" \
              -var "subnet_ids=${SUBNET_IDS}"
            cd ..
          """
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
