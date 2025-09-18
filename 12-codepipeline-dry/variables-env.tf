variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "env" {
  description = "Environment name"
}

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

variable "app_name" {
  description = "Application name used in CodePipeline and tagging"
  type        = string
  default     = "api"
}

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

