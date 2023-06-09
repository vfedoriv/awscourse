resource "aws_sqs_queue" "vf-sqs-1" {
 name = "edu-lohika-training-aws-sqs-queue"
}

output "sqs_arn" {
  value = aws_sqs_queue.vf-sqs-1.arn
}