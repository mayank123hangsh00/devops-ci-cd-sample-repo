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

        stage('Terraform Workflow') {
            steps {
                // Wrap all Terraform stages in a single credentials block
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: 'aws-creds']]) {
                    sh '''
                        cd terraform
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

                        # Terraform init
                        rm -f .terraform.lock.hcl
                        terraform init -input=false -reconfigure -upgrade

                        # Import existing resources (ignore errors if already imported)
                        terraform import aws_ecr_repository.app devops-sample-app || true
                        terraform import aws_cloudwatch_log_group.ecs /ecs/devops-sample-app || true
                        terraform import aws_security_group.app_sg sg-08513895b5f933feb || true
                        terraform import aws_lb_target_group.app arn:aws:elasticloadbalancing:ap-south-1:889913637557:targetgroup/devops-sample-app-tg/7375e34bfbb0dd85 || true

                        # Terraform apply
                        terraform apply -auto-approve -input=false

                        # Fetch ALB URL
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




