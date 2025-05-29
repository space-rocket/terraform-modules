resource "aws_cloudwatch_metric_alarm" "unhealthy_instance_count" {
  alarm_name          = format("%s-%s-%s", local.name_prefix, var.tg_name, "unhealthy-instances")
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "120"
  statistic           = "Average"
  threshold           = "1"
  datapoints_to_alarm = "1"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = aws_lb_target_group.this.arn_suffix
  }

  alarm_actions = [data.aws_sns_topic.alarm_topic.arn]
}
