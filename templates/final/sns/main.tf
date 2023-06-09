resource "aws_sns_topic" "vf-sns-topic-1" {
  name = "edu-lohika-training-aws-sns-topic"
}

#resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
#  topic_arn = aws_sns_topic.vf-sns-topic-1.arn
#  protocol  = "sqs"
#  endpoint  = var.sqs_arn
#}

resource "aws_sns_topic_subscription" "email-subscr" {
  topic_arn = aws_sns_topic.vf-sns-topic-1.arn
  protocol  = "email"
  endpoint  = "vitaliy.fedoriv@capgemini.com"
}