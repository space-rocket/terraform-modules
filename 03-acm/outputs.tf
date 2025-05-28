output "main_cert_arn" {
  value = data.aws_acm_certificate.main.arn
}

output "additional_cert_arns" {
  value = {
    for domain, cert in data.aws_acm_certificate.additional : domain => cert.arn
  }
}
