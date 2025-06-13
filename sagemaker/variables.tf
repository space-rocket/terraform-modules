variable "domain_name" {
  type        = string
  description = "SageMaker domain name"
}

variable "user_profile_name" {
  type        = string
  description = "Name of the user profile"
}

variable "execution_role_arn" {
  type        = string
  description = "IAM execution role ARN"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the domain"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for SageMaker domain"
}

variable "region" {
  type        = string
}

variable "project" {
  type        = string
}

variable "env" {
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
}
