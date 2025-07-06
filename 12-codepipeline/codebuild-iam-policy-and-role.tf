data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "code_build_role" {
  name               = "${local.env}-${local.task_name}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

data "aws_iam_policy_document" "codebuild_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.codepipeline_bucket.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.codepipeline_bucket.bucket}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
    resources = [
      "arn:aws:ecr:${local.region}:${local.account_id}:repository/${local.image_repo}"
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.codepipeline_bucket.bucket}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection",
      "codestar-connections:PassConnection"
    ]
    resources = [aws_codestarconnections_connection.github_connection.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [data.aws_kms_alias.s3kmskey.target_key_arn]
  }

  statement {
    effect  = "Allow"
    actions = ["kms:GenerateDataKey"]
    resources = [
      data.aws_kms_alias.s3kmskey.target_key_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:ListTaskDefinitions",
      "ecs:DescribeTaskDefinition",
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "iam:PassRole"
    ]
    # resources = [
    #   "arn:aws:ecs:${local.region}:${local.account_id}:task-definition/app",
    #   "arn:aws:ecs:${local.region}:${local.account_id}:service/${local.ecs_cluster_name}/dev-app-fargate-service"
    # ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_role_policy" {
  role   = aws_iam_role.code_build_role.name
  policy = data.aws_iam_policy_document.codebuild_policy_document.json
}