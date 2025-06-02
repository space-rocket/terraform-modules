locals {
  account_id                 = var.account_id
  project                    = var.project
  environment                = var.env
  env                        = var.env
  # app_name                   = var.app_name
  task_name                  = var.task_name
  region                     = var.region
  name                       = "${var.project}-${var.env}-${var.app_name}"
  git_repo                   = var.git_repo
  git_branch                 = var.git_branch
  ecs_cluster_name           = var.ecs_cluster_name
  ecs_service_name           = var.ecs_service_name
  fargate_ecs_task_role      = var.fargate_ecs_task_role
  fargate_ecs_execution_role = var.fargate_ecs_execution_role
  image_repo                 = var.image_repo
  port                       = var.port
  ssm_secret_path_prefix     = var.ssm_secret_path_prefix
  app_secrets                = var.app_secrets
  common_tags = {
    project     = local.project
    environment = local.environment
  }
}
