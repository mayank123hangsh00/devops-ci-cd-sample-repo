pipeline {
    agent any

    environment {
        AWS_REGION     = "ap-south-1"
        AWS_ACCOUNT_ID = "889913637557"
        SERVICE_NAME   = "devops-sample-app"
        IMAGE_TAG      = "${BUILD_NUMBER}"
        VPC_ID         = "vpc-0d117a5cf094c9777"
        SUBNET_IDS     = "subnet-0966bab78e8556aac,subnet-0bbbc05e87102f723,subnet-02d79f61af69e8c25"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "📥 Checking out source code..."
                git 'https://github.com/mayank123hangsh00/devops-ci-cd-sample-repo.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Building Docker image..."
                    sh '''
                        docker build -t ${SERVICE_NAME}:${IMAGE_TAG} .
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    echo "🔑 Logging in & pushing to Amazon ECR..."
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                        echo "🏷 Tagging image..."
                        docker tag ${SERVICE_NAME}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${SERVICE_NAME}:${IMAGE_TAG}

                        echo "📤 Pushing image..."
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${SERVICE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "🔧 Initializing Terraform..."
                        terraform init -input=false -no-color
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "🚀 Applying Terraform..."
                        terraform apply -input=false -auto-approve -no-color \
                          -var region=${AWS_REGION} \
                          -var aws_account_id=${AWS_ACCOUNT_ID} \
                          -var image_tag=${IMAGE_TAG} \
                          -var service_name=${SERVICE_NAME} \
                          -var vpc_id=${VPC_ID} \
                          -var "subnet_ids=[\\"subnet-0966bab78e8556aac\\", \\"subnet-0bbbc05e87102f723\\", \\"subnet-02d79f61af69e8c25\\"]"

                        echo "🌐 Fetching ALB DNS..."
                        terraform output -raw alb_dns_name > alb_dns.txt || true
                    '''
                }
            }
        }

        stage('Show URL') {
            steps {
                script {
                    sh '''
                        if [ -f terraform/alb_dns.txt ]; then
                          echo "✅ Application deployed successfully!"
                          echo "👉 URL: http://$(cat terraform/alb_dns.txt)"
                        else
                          echo "⚠ ALB DNS output not found."
                        fi
                    '''
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
