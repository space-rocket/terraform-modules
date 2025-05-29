**alarms.tf**
```tf
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
```

**locals.tf**
```tf
locals {
  name_prefix = format("%s-%s", var.project, var.env)

  common_tags = {
    Env       = var.env
    ManagedBy = "terraform"
    Project   = var.project
  }
}
```

**main.tf**
```tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.21"
    }
  }

  required_version = "~> 1.6"
}
```

**outputs.tf**
```tf
output "tg_arn" {
  value = aws_lb_target_group.this.arn
}
```

**sns.tf**
```tf
data "aws_sns_topic" "alarm_topic" {
  name = var.alarm_sns_topic_name
}
```

**tg.tf**
```tf
resource "aws_lb_target_group" "this" {
  name        = format("%s-%s", local.name_prefix, var.tg_name)
  port        = var.tg_port
  protocol    = var.tg_protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  deregistration_delay = var.deregistration_delay

  health_check {
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    enabled             = var.health_check_enabled
    interval            = var.health_check_interval
    path                = var.health_check_path
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = var.health_check_matcher
  }
}

resource "aws_lb_listener_rule" "host" {
  listener_arn = var.listener_443_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    host_header {
      values = var.host_headers
    }
  }
}
```

**variables-env.tf**
```tf
variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "region" {
  type        = string
  description = "AWS Region"
}
```

**variables.tf**
```tf
variable "tg_name" {
  type        = string
  description = "TG Name"
}

variable "tg_port" {
  type        = number
  description = "TG Port"
}

variable "tg_protocol" {
  type        = string
  description = "TG Protocol"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "deregistration_delay" {
  type        = number
  description = "TG deregistration delay. AWS default: 300"
}

variable "health_check_port" {
  type = number
}

variable "health_check_protocol" {
  type = string
}

variable "health_check_enabled" {
  type = bool
}

variable "health_check_interval" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "health_check_timeout" {
  type = number
}

variable "health_check_threshold" {
  type = number
}

variable "health_check_unhealthy_threshold" {
  type = number
}

variable "health_check_matcher" {
  type = string
}

variable "listener_443_arn" {
  type        = string
  description = "Listener for the TG (443)"
}

variable "host_headers" {
  type        = list(string)
  description = "Host headers for Listener rule"
}

variable "alb_arn_suffix" {
  type = string
}

variable "alarm_sns_topic_name" {
  type = string
}
```

