output "main_cert_arn" {
  value = data.aws_acm_certificate.main.arn
}

output "additional_cert_arns" {
  value = {
    for domain in var.additional_domains :
    domain => data.aws_acm_certificate.wildcard.arn
  }
}

output "debug_domain" {
  value = "*.${var.base_domain}"
}
