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
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "host" {
  listener_arn = var.listener_443_arn
  priority     = var.priority
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
