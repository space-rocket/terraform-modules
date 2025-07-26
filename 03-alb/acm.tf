data "aws_acm_certificate" "main" {
  domain      = var.main_domain
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_acm_certificate" "additional" {
  for_each    = toset(var.additional_domains)
  domain      = each.key
  statuses    = ["ISSUED"]
  most_recent = true
}
