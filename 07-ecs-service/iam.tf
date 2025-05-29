#######################
# IAM Role for the Task
#######################
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.app_name}-fargate-ecs-task-role"
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
  name   = "${var.app_name}-secrets-manager-policy"
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
  name   = "${var.app_name}-ecs-exec-policy"
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
  name   = "${var.app_name}-sqs-policy"
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
}