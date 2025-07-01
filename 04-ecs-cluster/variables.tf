variable "account_id" {
  type = string
}
variable "env" {
  type = string
}
variable "project" {
  type = string
}
variable "region" {
  type = string
}
variable "app_name" {
  type = string
}
variable "ssm_secret_path_prefixes" {
  description = "List of SSM parameter path prefixes to allow ECS task execution role to read"
  type        = list(string)
}

variable "ssm_secret_path_prefix" {
  type = string
}

variable "cluster_name_override" {
  type    = string
  default = ""
  description = "Optional override for ECS cluster name"
}
