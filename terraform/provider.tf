terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-terraform-backend-bucket"
    key            = "devops-sample-app/terraform.tfstate"
    region         = "us-east-1"   # ✅ match actual S3 bucket region
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = "ap-south-1"  # ✅ ECS infra region
}



