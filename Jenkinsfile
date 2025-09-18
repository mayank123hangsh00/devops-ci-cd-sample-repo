pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "ap-south-1"
        AWS_ACCOUNT_ID     = "889913637557"
        IMAGE_REPO         = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/devops-sample-app"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-token',
                    url: 'https://github.com/mayank123hangsh00/devops-ci-cd-sample-repo.git'
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    sh '''
                        aws ecr get-login-password --region $AWS_DEFAULT_REGION \
                        | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
                    '''
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                sh '''
                    docker build -t devops-sample-app .
                    docker tag devops-sample-app:latest $IMAGE_REPO:latest
                    docker push $IMAGE_REPO:latest
                '''
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    sh '''
                        cd terraform
                        rm -f .terraform.lock.hcl   # 🔥 delete old lock file
                        terraform init -input=false -reconfigure -upgrade
                        terraform apply -auto-approve -input=false
                    '''
                }
            }
        }

        stage('Fetch ALB URL') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    sh '''
                        cd terraform
                        terraform output alb_dns_name
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo "❌ Pipeline failed. Check logs for details."
        }
        success {
            echo "✅ Pipeline completed successfully."
        }
    }
}




