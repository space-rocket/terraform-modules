data "aws_acm_certificate" "main" {
  domain      = var.base_domain
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_acm_certificate" "additional" {
  for_each = toset(var.additional_domains)

  domain   = each.value
  types    = ["AMAZON_ISSUED"]
  statuses = ["ISSUED"]

  # Must be same region as the ALB
  region = var.aws_region
  most_recent = true
}

