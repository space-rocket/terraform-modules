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

  depends_on = [
    aws_s3_bucket_policy.alb_logs
  ]
  
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
