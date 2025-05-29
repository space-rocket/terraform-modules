**acm.tf**
```tf
# data "aws_acm_certificate" "main" {
#   domain      = var.main_domain
#   statuses    = ["ISSUED"]
#   most_recent = true
# }

# data "aws_acm_certificate" "additional" {
#   for_each    = toset(var.additional_domains)
#   domain      = each.key
#   statuses    = ["ISSUED"]
#   most_recent = true
# }
```

**alb_alarms.tf**
```tf
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = format("%s-%s", local.name_prefix, "microservices-alb-5xx")
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  datapoints_to_alarm = "1"
  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = [data.aws_sns_topic.alarm_topic.arn]
}
resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name          = format("%s-%s", local.name_prefix, "microservices-target-5xx")
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.target_5xx_threshold
  datapoints_to_alarm = "1"
  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = [data.aws_sns_topic.alarm_topic.arn]
}```

**alb.tf**
```tf
resource "aws_lb" "this" {
  name               = local.alb_name
  internal           = false # tfsec:ignore:AWS005
  load_balancer_type = "application"
  security_groups    = [var.lb_sg.id]
  subnets            = var.lb_subnets[*].id
  enable_http2       = true
  ip_address_type    = "dualstack"

  access_logs {
    enabled = var.logs_enabled
    bucket  = aws_s3_bucket.logs[0].id
    prefix  = var.logs_prefix
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "default_80" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      status_code = "HTTP_301"
      protocol    = "HTTPS"
      port        = 443
    }
  }
}

resource "aws_lb_listener" "default_app_443" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.lb_ssl_policy
  certificate_arn   = var.main_cert_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access denied"
      status_code  = "403"
    }
  }
}

# resource "aws_lb_listener_certificate" "additional_certs" {
#   for_each        = data.aws_acm_certificate.additional
#   listener_arn    = aws_lb_listener.default_app_443.arn
#   certificate_arn = each.value.arn
# }
```

**locals.tf**
```tf
locals {
  name_prefix = format("%s-%s", var.project, var.env)
  alb_name    = format("%s-%s", local.name_prefix, "alb")

  common_tags = {
    Env       = var.env
    ManagedBy = "terraform"
    Project   = var.project
  }
  # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html#attach-bucket-policy
  lb_account_id = lookup({
    "us-east-1"    = "127311923021"
    "us-east-2"    = "033677994240"
    "us-west-1"    = "027434742980"
    "us-west-2"    = "797873946194"
    },
    var.aws_region
  )
}
```

**logging_s3_bucket.tf**
```tf
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = var.logs_bucket == null ? 0 : 1

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = var.logs_bucket == null ? 0 : 1

  bucket = aws_s3_bucket.logs[0].id

  rule {
    id      = "delete"
    status  = "Enabled"

    expiration {
      days = var.logs_expiration
    }
  }

}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count  = var.logs_bucket == null ? 0 : 1
  bucket = aws_s3_bucket.logs[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket" "logs" {
  count = var.logs_bucket == null ? 0 : 1

  bucket = var.logs_bucket

  force_destroy = var.logs_bucket_force_destroy

  tags = local.common_tags
}

data "aws_iam_policy_document" "alb_logs_s3" {
  count = var.logs_bucket == null ? 0 : 1

  statement {
    sid = "AlbS301"

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs[0].arn}/${var.logs_prefix}/AWSLogs/${var.account_id}/*"]

    principals {
      # identifiers = ["arn:aws:iam::${local.lb_account_id}:root"]
      identifiers = ["elasticloadbalancing.amazonaws.com"]
      type        = "AWS"
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid = "AlbS302"

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs[0].arn}/${var.logs_prefix}/AWSLogs/${var.account_id}/*"]

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    sid = "AlbS303"

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs[0].arn]

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    sid = "AllowALBAccess"

    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.logs[0].arn}/${var.logs_prefix}/AWSLogs/${var.account_id}/*"
    ]

    principals {
      identifiers = ["elasticloadbalancing.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    sid = "AllowLogsDelivery"
    actions = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs[0].arn}/${var.logs_prefix}/AWSLogs/${var.account_id}/*"]

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid       = "ALBGetBucketAcl"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs[0].arn]
    principals {
      identifiers = ["elasticloadbalancing.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count = var.logs_bucket == null ? 0 : 1

  bucket = aws_s3_bucket.logs[0].id
  policy = data.aws_iam_policy_document.alb_logs_s3[0].json
}
```

**main.tf**
```tf
```

**outputs.tf**
```tf
output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "listener_443_arn" {
  value = aws_lb_listener.default_app_443.arn
}

output "arn_suffix" {
  value = aws_lb.this.arn_suffix
}

output "alias_zones_debug" {
  value = local.alias_zones
}```

**route53.tf**
```tf
data "aws_route53_zone" "alias" {
  for_each = local.alias_zones
  name     = each.key
}

locals {
  alias_zones = toset([
    for alias in var.create_aliases :
    alias["zone"]
  ])

  alias_fqdns_with_zones = {
    for alias in var.create_aliases : format("%s.%s", alias["name"], alias["zone"]) => alias["zone"]
  }
}

resource "aws_route53_record" "alias" {
  for_each = local.alias_fqdns_with_zones

  zone_id = data.aws_route53_zone.alias[each.value].zone_id
  name    = each.key
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = false
  }
}
```

**sns.tf**
```tf
data "aws_sns_topic" "alarm_topic" {
  name = var.alarm_sns_topic_name
}```

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

variable "aws_region" {
  type        = string
  description = "AWS Region"
}
```

**variables.tf**
```tf
variable "main_domain" {
  description = "The main for ACM cert"
  type        = string
}

variable "additional_domains" {
  description = "Additional domains for SNI SSL certificates"
  type        = list(string)
  default     = []
}

variable "main_cert_arn" {
  description = "ACM ARN for the main domain"
  type        = string
}

# variable "additional_cert_arns" {
#   description = "Map of additional domain -> ACM ARN"
#   type        = map(string)
#   default     = {}
# }

# variable "additional_cert_arn" {
#   type = string
# }


variable "vpc" {}

variable "lb_sg" {
  description = "The ALB security group"
}

variable "lb_subnets" {}

variable "logs_enabled" {
  description = "ALB app logging enabled"
  type        = bool
}

variable "logs_prefix" {
  description = "The ALB app logs prefix"
  type        = string
}

variable "logs_bucket" {
  type        = string
  description = "ALB Logs bucket name"
  default     = "LOGS BUCKET NET SET!"
}

variable "logs_expiration" {
  type        = number
  description = "ALB Logs expiration (S3)"
}

variable "logs_bucket_force_destroy" {
  type        = bool
  default     = false
  description = "Force terraform destruction of the ALB Logs bucket?"
}

variable "lb_ssl_policy" {
  description = "The ALB ssl policy"
  type        = string
}

variable "create_aliases" {
  type        = list(map(string))
  description = "List of DNS Aliases to create pointing at the ALB"
}

variable "alarm_sns_topic_name" {
  type = string
}

variable "alb_5xx_threshold" {
  type    = number
  default = 20
}

variable "target_5xx_threshold" {
  type    = number
  default = 20
}```

