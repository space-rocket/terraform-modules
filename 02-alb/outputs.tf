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
}