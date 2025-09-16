pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_ACCOUNT_ID     = credentials('aws-account-id')
        AWS_ACCESS_KEY_ID  = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    }

    stages {
        stage('Checkout') {
            steps {
                echo "📥 Checking out source code..."
                git branch: 'main', url: 'https://github.com/mayank123hangsh00/devops-ci-cd-sample-repo.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh 'docker build -t myapp:latest .'
            }
        }

        stage('Push to ECR') {
            steps {
                echo "📤 Pushing Docker image to ECR..."
                sh '''
                    aws ecr get-login-password --region $AWS_DEFAULT_REGION \
                    | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com

                    docker tag myapp:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/myapp:latest
                    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/myapp:latest
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                echo "⚙️ Terraform Init..."
                sh 'cd infra && terraform init'
            }
        }

        stage('Terraform Apply') {
            steps {
                echo "🚀 Deploying with Terraform..."
                sh 'cd infra && terraform apply -auto-approve'
            }
        }

        stage('Show URL') {
            steps {
                echo "🌍 Application URL:"
                sh 'terraform output -raw app_url'
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs above."
            archiveArtifacts artifacts: '**/terraform.tfstate', allowEmptyArchive: true
        }
    }
}
