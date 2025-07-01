data "aws_sns_topic" "alarm_topic" {
  arn = var.alarm_sns_topic_arn
}
