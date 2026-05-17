resource "aws_sqs_queue" "simulations" {
  name                       = "cloud-presti-simulations-queue"
  visibility_timeout_seconds = 300
}
