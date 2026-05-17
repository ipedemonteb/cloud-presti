resource "aws_sqs_queue" "simulations" {
  name                       = "${var.project_name}-simulations-queue"
  visibility_timeout_seconds = 300
}
