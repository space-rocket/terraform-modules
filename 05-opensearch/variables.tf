variable "account_id" {}
variable "env" {}
variable "project" {}
variable "aws_region" {}

variable "domain_name" {
  description = "Name of the OpenSearch domain"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for OpenSearch"
  type        = list(string)
}

variable "sg_ids" {
  description = "List of security group IDs for OpenSearch"
  type        = list(string)
}

variable "admin_name" {
  type        = string
  description = "Master user for FGAC"
}

variable "admin_password" {
  type        = string
  description = "Master user password"
  sensitive   = true
}

variable "engine_version" {
  default     = "OpenSearch_2.11"
  description = "Engine version for the OpenSearch domain"
}

variable "instance_type" {
  default     = "t3.medium.search"
  description = "OpenSearch instance type"
}

variable "instance_count" {
  description = "Number of OpenSearch data nodes"
}

variable "zone_awareness_enabled" {
  default     = true
  description = "Whether to enable zone awareness"
}

variable "volume_size" {
  default     = 10
  description = "EBS volume size (GiB)"
}

variable "volume_type" {
  default     = "gp3"
  description = "EBS volume type"
}

variable "admin_email" {
  type        = string
  description = "Admin contact email"
  default     = "ADMIN EMAIL NOT SET!"
}

variable "my_ip" {
  description = "Your machine's public IP address for whitelisting access to OpenSearch"
  type        = string
}

