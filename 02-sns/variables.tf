variable "topic_name" {
  type = string
}

variable "subscriptions" {
  type    = map(map(string))
  default = {}
}
