data "aws_acm_certificate" "main" {
  domain      = var.base_domain
  statuses    = ["ISSUED"]
  most_recent = true
  region      = var.aws_region
}

data "aws_acm_certificate" "additional" {
  for_each = toset(var.additional_domains)

  domain      = each.value
  statuses    = ["ISSUED"]
  types       = ["AMAZON_ISSUED"]
  most_recent = true
  region      = var.aws_region
}
