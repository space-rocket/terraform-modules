variable "tg_name" {
  type        = string
  description = "TG Name"
}

variable "tg_port" {
  type        = number
  description = "TG Port"
}

variable "tg_protocol" {
  type        = string
  description = "TG Protocol"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "deregistration_delay" {
  type        = number
  description = "TG deregistration delay. AWS default: 300"
}

variable "health_check_port" {
  type = number
}

variable "health_check_protocol" {
  type = string
}

variable "health_check_enabled" {
  type = bool
}

variable "health_check_interval" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "health_check_timeout" {
  type = number
}

variable "health_check_threshold" {
  type = number
}

variable "health_check_unhealthy_threshold" {
  type = number
}

variable "health_check_matcher" {
  type = string
}

variable "listener_443_arn" {
  type        = string
  description = "Listener for the TG (443)"
}

variable "host_headers" {
  type        = list(string)
  description = "Host headers for Listener rule"
}

variable "alb_arn_suffix" {
  type = string
}

variable "alarm_sns_topic_name" {
  type = string
}

variable "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  type        = string
}

variable "priority" {
  type        = number
  description = "Priority for the listener rule. Must be unique per rule on the same listener."
}
