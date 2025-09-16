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
  default = "vpc-0d117a5cf094c9777"
}

variable "subnet_ids" {
  default = [
    "subnet-0966bab78e8556aac",
    "subnet-0bbbc05e87102f723",
    "subnet-02d79f61af69e8c25"
  ]
}
