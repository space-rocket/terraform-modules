variable "main_domain" {
  description = "The main for ACM cert"
  type        = string
}

variable "additional_domains" {
  description = "Additional domains for SNI SSL certificates"
  type        = list(string)
  default     = []
}

variable "main_cert_arn" {
  description = "ACM ARN for the main domain"
  type        = string
}

variable "additional_cert_arns" {
  description = "Map of additional domain -> ACM ARN"
  type        = map(string)
  default     = {}
}

# variable "additional_cert_arn" {
#   type = string
# }


variable "vpc" {}

variable "lb_sg" {
  description = "The ALB security group"
}

variable "lb_subnets" {}

variable "logs_enabled" {
  description = "ALB app logging enabled"
  type        = bool
}

variable "logs_prefix" {
  description = "The ALB app logs prefix"
  type        = string
}

variable "logs_bucket" {
  type        = string
  description = "ALB Logs bucket name"
  default     = null
}

variable "logs_expiration" {
  type        = number
  description = "ALB Logs expiration (S3)"
}

variable "logs_bucket_force_destroy" {
  type        = bool
  default     = false
  description = "Force terraform destruction of the ALB Logs bucket?"
}

variable "lb_ssl_policy" {
  description = "The ALB ssl policy"
  type        = string
}

variable "create_aliases" {
  type        = list(map(string))
  description = "List of DNS Aliases to create pointing at the ALB"
}

variable "alarm_sns_topic_name" {
  type = string
}

variable "alb_5xx_threshold" {
  type    = number
  default = 20
}

variable "target_5xx_threshold" {
  type    = number
  default = 20
}