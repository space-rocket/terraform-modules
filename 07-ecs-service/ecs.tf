########################
# ECS Task Definition
########################
# Template for container definitions
locals {
  # log_stream_prefix = "${formatdate("yyyy-MM-dd", timestamp())}"
  log_stream_prefix = "${formatdate("2006-01-02", timestamp())}"

  app_template_path = "${path.module}/app.json"

  app_config = templatefile(
    local.app_template_path,
    {
      task_name        = var.task_name
      log_group_name   = var.log_group_name
      app_image        = var.app_image
      app_port         = var.app_port
      app_env          = var.env
      project          = var.project
      region           = var.region
      account_id       = var.account_id
      fargate_cpu      = var.fargate_cpu
      fargate_memory   = var.fargate_memory
      app_environments = jsonencode(var.app_environments)
      app_secrets      = jsonencode(var.app_secrets)
      log_stream_prefix = local.log_stream_prefix
    }
  )
}


resource "aws_ecs_task_definition" "app" {
  family                   = var.task_name
  container_definitions    = local.app_config
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.runtime_platform
  }

  execution_role_arn = var.ecs_execution_role
  task_role_arn      = aws_iam_role.ecs_task_role.arn
}

########################
# ECS Service
########################
resource "aws_ecs_service" "ecs_app_service" {
  name                   = "${var.task_name}-fargate-service"
  cluster                = var.ecs_cluster_id
  task_definition        = aws_ecs_task_definition.app.arn
  desired_count          = var.app_count
  enable_execute_command = true

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 2
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }

  network_configuration {
    security_groups  = [var.fargate_ecs_task_sg.id]
    subnets          = var.fargate_subnets[*].id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.tg_arn
    container_name   = var.task_name
    container_port   = var.app_port
  }

  depends_on = [var.listener_443_arn]
}
