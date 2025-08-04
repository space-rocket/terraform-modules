variable "slack_webhook_url" {
  description = "The full Slack incoming webhook URL"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS Topic ARN to subscribe Lambda to"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming Lambda function and resources"
  type        = string
}
