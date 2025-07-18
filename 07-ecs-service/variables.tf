variable "env" {
  type = string
}
variable "project" {
  type = string
}
variable "region" {
  type = string
}
variable "account_id" {
  type = string
}

variable "ecs_cluster_id" {
  type = string
}
variable "ecs_cluster_name" {
  type = string
}
variable "ecs_execution_role" {
  type = string
}

variable "task_name" {
  type = string
}

variable "log_group_name" {
  type = string
}

variable "app_image" {
  type = string
}
variable "app_port" {
  type = number
}
variable "app_count" {
  type = number
}
variable "fargate_cpu" {
  type = number
}
variable "fargate_memory" {
  type = number
}
variable "runtime_platform" {
  type = string
}

variable "fargate_ecs_task_sg" {
  # Could be type = string or object(...) if you want.
}
variable "fargate_subnets" {
  # Could be type = list(string) or list(object(...)), etc.
}
variable "tg_arn" {
  type = string
}
variable "listener_443_arn" {
  type = string
}

variable "ssm_secret_path_prefix" {
  type = string
}

variable "app_environments" {
  description = "List of env vars to inject"
  type = list(object({
    name  = string
    value = string
  }))
}


variable "app_secrets" {
  description = "Secrets for ECS container definition"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "healthcheck_interval" {
  type        = number
  default     = 30
  description = "Time between health checks (seconds)"
}

variable "healthcheck_timeout" {
  type        = number
  default     = 5
  description = "Health check timeout duration (seconds)"
}

variable "healthcheck_retries" {
  type        = number
  default     = 3
  description = "Number of retries before failing"
}

variable "healthcheck_start_period" {
  type        = number
  default     = 30
  description = "Grace period before ECS starts checking health (seconds)"
}

variable "app_name" {
  description = "The name of the application"
  type        = string
}

