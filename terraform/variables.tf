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
  type    = bool
  default = false
}
variable "security_group_id" {
  description = "Security group ID for ECS tasks/ALB"
  type        = string
}




