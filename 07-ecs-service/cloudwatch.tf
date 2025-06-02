#######################
# CloudWatch Log Group
#######################
resource "aws_cloudwatch_log_group" "fargate_task_log_group" {
  name              = "${var.task_name}-log-group"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "fargate_task_log_stream" {
  name           = "${var.task_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.fargate_task_log_group.name
}