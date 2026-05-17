# LabRole pre-existente en AWS Academy (no se pueden crear IAM roles)
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}
