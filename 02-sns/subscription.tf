resource "aws_sns_topic_subscription" "this" {
  for_each = var.subscriptions
  topic_arn = aws_sns_topic.this.arn
  protocol  = each.value["protocol"]
  endpoint  = each.value["endpoint"]
}