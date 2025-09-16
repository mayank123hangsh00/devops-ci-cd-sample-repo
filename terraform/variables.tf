variable "region" {
  default = "ap-south-1"
}

variable "aws_account_id" {
  type = string
}

variable "image_tag" {
  default = "latest"
}

variable "service_name" {
  default = "devops-sample-app"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "use_existing" {
  description = "If true, Terraform will read existing resources (ECR, SG, log group, IAM role, ALB/TG) by name instead of trying to create them."
  type        = bool
  default     = true
}
