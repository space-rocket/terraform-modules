data "aws_acm_certificate" "main" {
  domain      = var.base_domain
  statuses    = ["ISSUED"]
  most_recent = true
}

