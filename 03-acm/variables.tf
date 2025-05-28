variable "base_domain" {
  description = "Primary domain name (e.g. example.space-rocket.com)"
  type        = string
}

variable "additional_domains" {
  description = "List of SAN domains (e.g. api.example.space-rocket.com)"
  type        = list(string)
  default     = []
}

variable "aws_region" {
  description = "AWS region where ACM is created (must match ALB region)"
  type        = string
}
