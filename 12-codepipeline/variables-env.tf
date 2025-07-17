variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

# variable "admin_email" {
#   description = "For sending alarm notifications"
# }

# variable "domain" {
#   description = "The main domain name, ex: example.com"
# }

variable "env" {
  description = "Environment name"
}

# variable "backend_app_name" {
#   type        = string
#   description = "The backend app name, ex: example-backend"
# }

# variable "backend_alias" {
#   type        = string
#   description = "The subdomain domain name for the backend api, ex: app in api.example.com"
# }

variable "git_branch" {
  description = "The branch to trigger CI/CD pipeline, ex: main"
  type        = string
  default     = "cicd"
}

variable "git_repo" {
  description = "The org's Github repo for the frontend app, ex: Spoon/Knife"
  type        = string
  default     = "Spoon/Knife"
}

variable "port" {
  description = "The port the backend service listens on, ex: 5000"
  type        = number
  default     = 5000
}

# variable "frontend_app_name" {
#   type        = string
#   description = "The frontend app name, ex: example-frontend"
# }

# variable "frontend_alias" {
#   type        = string
#   description = "The subdomain domain name for the frontend app, ex: app in app.example.com"
# }

# variable "frontend_git_branch" {
#   description = "The branch to trigger CI/CD pipeline, ex: main"
#   type        = string
#   default     = "main"
# }

# variable "frontend_git_repo" {
#   description = "The org's Github repo for the frontend app, ex: Spoon/Knife"
#   type        = string
#   default     = "Spoon/Knife"
# }

variable "image_repo" {
  description = "The ecr repo, ex: Spoon/Knife"
  type        = string
  default     = "Spoon/Knife"
}

variable "project" {
  description = "Project name"
}

variable "region" {
  description = "AWS Region"
}

variable "ssm_secret_path_prefix" {
  description = "Prefix for retrieving secrets from SSM"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster used by the backend"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service used by the backend"
  type        = string
}

variable "fargate_ecs_task_role" {
  description = "IAM Role for ECS Task"
  type        = string
}

variable "fargate_ecs_execution_role" {
  description = "IAM Role for ECS Task execution"
  type        = string
}

# variable "app_name" {
#   description = "Application name used in CodePipeline and tagging"
#   type        = string
# }

variable "task_name" {
  description = "Application name used in CodePipeline and tagging"
  type        = string
}

variable "log_group_name" {
  type = string
}

variable "app_secrets" {
  description = "List of secret objects with name and valueFrom"
  type        = list(object({
    name      = string
    valueFrom = string
  }))
}

variable "codebuild_compute_type" {
  type        = string
  description = "CodeBuild compute type"
  default     = "BUILD_GENERAL1_MEDIUM"
}

variable "codebuild_image" {
  type        = string
  description = "CodeBuild container image"
  default     = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
}


