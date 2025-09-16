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

# Toggle to use existing ALB/TG or create new
variable "use_existing" {
  type    = bool
  default = false
}
