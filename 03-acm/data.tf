data "aws_acm_certificate" "main" {
  domain      = var.base_domain
  statuses    = ["ISSUED"]
  most_recent = true
}

# data "aws_acm_certificate" "additional" {
#   for_each    = toset(var.additional_domains)
#   domain      = each.key
#   statuses    = ["ISSUED"]
#   most_recent = true
# }

# data "aws_acm_certificate" "additional" {
#   domain      = "*.${var.base_domain}"
#   statuses    = ["ISSUED"]
#   most_recent = true
# }
# 
data "aws_acm_certificate" "wildcard" {
  domain      = "*.${var.base_domain}"
  statuses    = ["ISSUED"]
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

