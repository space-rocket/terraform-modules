locals {
  log_stream_prefix          = "${formatdate("2006-01-02", timestamp())}"
  account_id                 = var.account_id
  project                    = var.project
  environment                = var.env
  env                        = var.env
  log_group_name             = var.log_group_name
  region                     = var.region
  git_repo                   = var.git_repo
  git_branch                 = var.git_branch
  ecs_cluster_name           = var.ecs_cluster_name
  image_repo                 = var.image_repo
  
  ssm_secret_path_prefix     = var.ssm_secret_path_prefix
  app_secrets                = var.app_secrets
  common_tags = {
    project     = local.project
    environment = local.environment
  }
  codebuild_compute_type    = var.codebuild_compute_type
  codebuild_image           = var.codebuild_image
  codebuild_type = can(regex("aarch64", var.codebuild_image)) ? "ARM_CONTAINER" : "LINUX_CONTAINER"
}
