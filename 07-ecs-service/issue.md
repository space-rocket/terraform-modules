**modules/07-ecs-service/cloudwatch.tf**
```tf
#######################
# CloudWatch Log Group
#######################
resource "aws_cloudwatch_log_group" "fargate_task_log_group" {
  name              = "${var.log_group_name}"
  retention_in_days = 30
}

# resource "aws_cloudwatch_log_stream" "fargate_task_log_stream" {
#   name           = "${var.task_name}"
#   log_group_name = aws_cloudwatch_log_group.fargate_task_log_group.name
# }```

**modules/07-ecs-service/ecs.tf**
```tf
########################
# ECS Task Definition
########################
# Template for container definitions
locals {
  # log_stream_prefix = "${formatdate("yyyy-MM-dd", timestamp())}"
  # log_stream_prefix = "${formatdate("YYYY-MM-DD", timestamp())}"

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
```

**modules/07-ecs-service/iam.tf**
```tf
#######################
# IAM Role for the Task
#######################
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.task_name}-fargate-ecs-task-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_policy.json
}

data "aws_iam_policy_document" "ecs_task_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Example: attach a Secrets Manager policy so this task can read secrets:
resource "aws_iam_policy" "secrets_manager_policy" {
  name   = "${var.task_name}-secrets-manager-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "secrets_manager_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

# ECS Exec policy
resource "aws_iam_policy" "ecs_exec_policy" {
  name   = "${var.task_name}-ecs-exec-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_exec_policy.arn
}

# Example SQS policy
resource "aws_iam_policy" "sqs_policy" {
  name   = "${var.task_name}-sqs-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:DeleteMessage",
        "sqs:ReceiveMessage",
        "sqs:SendMessage"
      ],
      "Resource": "arn:aws:sqs:${var.region}:${var.account_id}:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sqs_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.sqs_policy.arn
}```

**modules/07-ecs-service/outputs.tf**
```tf
output "ecs_service_name" {
  value = aws_ecs_service.ecs_app_service.name
}

output "ecs_task_role_name" {
  value       = aws_iam_role.ecs_task_role.name
  description = "The name of the ECS task role."
}

output "task_name" {
  value       = var.task_name
  description = "The name of the app that this service deploys."
}


```

**modules/07-ecs-service/variables.tf**
```tf
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

```

