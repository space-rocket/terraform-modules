provider "aws" {
  region = "us-west-2"
}

data "aws_acm_certificate" "main" {
  domain      = var.base_domain
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_acm_certificate" "wildcard" {
  domain      = "dashtwo.space-rocket.com"
  statuses    = ["ISSUED"]
  most_recent = true
}


