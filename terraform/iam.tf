# Pre-existing LabRole in AWS Academy (IAM roles cannot be created)
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}
