variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "cloud-presti"
}

variable "bucket_name" {
  description = "Nombre del bucket S3 para el frontend estático"
  type        = string
}
