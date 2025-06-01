locals {
  account_id                 = var.account_id
  project                    = var.project
  environment                = var.env
  region                     = local.region
  name                       = "${var.project}-${var.env}-${var.app_name}"
  git_repo                   = var.git_repo
  ecs_cluster_name           = var.ecs_cluster_name
  ecs_service_name           = var.ecs_service_name
  fargate_ecs_task_role      = var.fargate_ecs_task_role
  fargate_ecs_execution_role = var.fargate_ecs_execution_role
  image_repo                 = var.image_repo


  app_name               = var.app_name
  port                   = var.port
  ssm_secret_path_prefix = var.ssm_secret_path_prefix

  common_tags = {
    project     = local.project
    environment = local.environment
  }
}
