variable "vpc_ip_block" {
  type = string
}

variable "subnet_cidr_public" {
  type = string
}

variable "subnet_cidr_private" {
  type = string
}

variable "new_bits_private" {
  type = number
}

variable "new_bits_public" {
  type = number
}

variable "natgw_count" {
  type        = string
  description = "all | none | one"
}

variable "az_num" {
  type        = number
  description = "Number of used AZ"
}

variable "public_ips" {
  type = map(string)
}

variable "public_ips_v6" {
  type = map(string)
}

variable "app_ports" {
  type        = list(number)
  description = "Ports on app servers to open for ALB"
}
