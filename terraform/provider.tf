terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Keep backend config here if you use S3/DynamoDB for remote state
backend "s3" {
  bucket         = "my-terraform-backend-bucket"
  key            = "devops-sample-app/terraform.tfstate"
  region         = "ap-south-1"
  dynamodb_table = "terraform-locks"
}

