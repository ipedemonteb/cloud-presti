variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "cloud-presti"
}

variable "bucket_name" {
  description = "S3 bucket name for the static frontend"
  type        = string
}
