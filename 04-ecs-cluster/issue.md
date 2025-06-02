**modules/07-ecs-cluster/main.tf**
```tf
resource "aws_ecs_cluster" "ecs_app_cluster" {
  name = var.cluster_name_override != "" ? var.cluster_name_override : "${var.env}-${var.project}-ecs-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "default" {
  cluster_name          = aws_ecs_cluster.ecs_app_cluster.name
  capacity_providers    = ["FARGATE"] # You can add "FARGATE_SPOT" if desired
  default_capacity_provider_strategy {
    base              = 1
    weight            = 1
    capacity_provider = "FARGATE"
  }
}

# ECS Execution Role (used by ECS to pull images, manage logs, etc.)
resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.env}-${var.project}-ecs-execution-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_assume_role_policy.json
}

data "aws_iam_policy_document" "ecs_execution_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# (Optionally) attach a policy for reading parameters from SSM under the
# execution role, if you prefer that design
# resource "aws_iam_policy" "ssm_params_policy" {
#   name   = "${var.env}-${var.project}-ssm-params-policy"
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = ["ssm:GetParameters"],
#         Resource = [
#           for prefix in var.ssm_secret_path_prefixes : "${prefix}/*"
#         ]
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ssm_params_policy_attachment" {
#   role       = aws_iam_role.ecs_execution_role.name
#   policy_arn = aws_iam_policy.ssm_params_policy.arn
# }```

**modules/07-ecs-cluster/outputs.tf**
```tf
output "ecs_cluster_id" {
  value = aws_ecs_cluster.ecs_app_cluster.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_app_cluster.name
}

output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution_role.arn
}
```

**modules/07-ecs-cluster/variables.tf**
```tf
variable "account_id" {
  type = string
}
variable "env" {
  type = string
}
variable "project" {
  type = string
}
variable "region" {
  type = string
}

variable "ssm_secret_path_prefixes" {
  description = "List of SSM parameter path prefixes to allow ECS task execution role to read"
  type        = list(string)
}

variable "cluster_name_override" {
  type    = string
  default = ""
  description = "Optional override for ECS cluster name"
}
```

