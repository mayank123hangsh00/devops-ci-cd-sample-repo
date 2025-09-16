pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        SERVICE_NAME = "devops-sample-app"
        IMAGE_TAG = "latest"
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/mayank123hangsh00/devops-ci-cd-sample-repo.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                    $(aws ecr get-login --no-include-email --region $AWS_REGION)
                    docker build -t $SERVICE_NAME:$IMAGE_TAG .
                    docker tag $SERVICE_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SERVICE_NAME:$IMAGE_TAG
                    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SERVICE_NAME:$IMAGE_TAG
                    """
                }
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh """
                terraform apply -auto-approve \
                  -var region=$AWS_REGION \
                  -var aws_account_id=$AWS_ACCOUNT_ID \
                  -var image_tag=$IMAGE_TAG \
                  -var service_name=$SERVICE_NAME \
                  -var vpc_id=$VPC_ID \
                  -var 'subnet_ids=["$SUBNET1","$SUBNET2"]' \
                  -var use_existing=false
                """
            }
        }
    }
}
