pipeline {
    agent any
    tools {
        git 'git'   // name must match what you configured in Jenkins Tools
    }

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

        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    sh '''
                        cd terraform
                        rm -f .terraform.lock.hcl   # cleanup old lock file
                        terraform init -input=false -reconfigure -upgrade
                    '''
                }
            }
        }

        stage('Terraform Import Existing Resources') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    sh '''
                        cd terraform
                        terraform import aws_ecr_repository.app devops-sample-app || true
                        terraform import aws_cloudwatch_log_group.ecs /ecs/devops-sample-app || true
                        terraform import aws_security_group.app_sg sg-08513895b5f933feb || true
                        terraform import aws_lb_target_group.app arn:aws:elasticloadbalancing:ap-south-1:889913637557:targetgroup/devops-sample-app-tg/7375e34bfbb0dd85 || true
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    sh '''
                        cd terraform
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

