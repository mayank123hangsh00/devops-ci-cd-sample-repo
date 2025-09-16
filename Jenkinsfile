pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = "889913637557"
        AWS_DEFAULT_REGION = "ap-south-1"
        IMAGE_REPO_NAME = "devops-sample-app"
        IMAGE_TAG = "latest"
        ECR_REPO_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/mayank123hangsh00/devops-ci-cd-sample-repo.git'
            }
        }

        stage('Login to ECR') {
            steps {
                script {
                    sh """
                    aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | \
                    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
                    """
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    sh """
                    docker build -t ${IMAGE_REPO_NAME}:${IMAGE_TAG} .
                    docker tag ${IMAGE_REPO_NAME}:${IMAGE_TAG} ${ECR_REPO_URI}:${IMAGE_TAG}
                    docker push ${ECR_REPO_URI}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                script {
                    sh """
                    cd terraform
                    terraform init -input=false
                    terraform apply -auto-approve -input=false
                    """
                }
            }
        }

        stage('Fetch ALB DNS') {
            steps {
                script {
                    sh """
                    cd terraform
                    terraform output alb_dns_name
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful! Visit the ALB DNS to test your app."
        }
        failure {
            echo "❌ Pipeline failed. Check logs for details."
        }
    }
}
