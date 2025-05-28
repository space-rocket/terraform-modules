data "aws_sns_topic" "alarm_topic" {
  name = var.alarm_sns_topic_name
}