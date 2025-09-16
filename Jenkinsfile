pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        APP_NAME   = "devops-sample-app"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/mayank123hangsh00/devops-ci-cd-sample-repo.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh '$(aws ecr get-login --no-include-email --region $AWS_REGION)'
                    sh "docker build -t $APP_NAME ."
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    ECR_URL = sh(
                        script: "terraform -chdir=terraform output -raw ecr_repo_url",
                        returnStdout: true
                    ).trim()
                    sh "docker tag $APP_NAME:latest $ECR_URL:latest"
                    sh "docker push $ECR_URL:latest"
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Get ALB DNS and Print App URL') {
            steps {
                script {
                    APP_URL = sh(
                        script: "terraform -chdir=terraform output -raw alb_dns_name",
                        returnStdout: true
                    ).trim()
                    echo "✅ Application is deployed successfully!"
                    echo "🌍 Access it here: http://${APP_URL}"
                }
            }
        }
    }
}
