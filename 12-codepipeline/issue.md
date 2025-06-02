**codebuild-build.tf**
```tf
resource "aws_codebuild_project" "build" {
  name          = "${local.name}-codebuild-build-project"
  description   = "${local.name} Codebuild Build Project"
  build_timeout = 5
  service_role  = aws_iam_role.code_build_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_bucket.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
    type                        = "ARM_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = local.image_repo
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group-from-build"
      stream_name = "log-stream-from-build"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codepipeline_bucket.bucket}/build-log"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      env:
        variables:
          AWS_REGION: "${local.region}"
          S3_BUCKET: ""
          S3_KEY: ""
      phases:
        install:
          commands:
            - echo ✅ Begin install phase 
        pre_build:
          commands:
            - echo 👉 AWS_DEFAULT_REGION $AWS_DEFAULT_REGION
            - echo 👉 AWS_ACCOUNT_ID $AWS_ACCOUNT_ID
            - echo 👉 IMAGE_REPO_NAME $IMAGE_REPO_NAME
            - echo 👉 COMMIT_ID $CODEBUILD_RESOLVED_SOURCE_VERSION
            - export IMAGE_TAG=$CODEBUILD_RESOLVED_SOURCE_VERSION
            - echo 👉 IMAGE_TAG $IMAGE_TAG
            - echo Logging in to Amazon ECR...
            - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
        build:
          commands:
            - echo "🚀 Starting build phase..."
            - echo Building the Docker image...
            - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
            - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
        post_build:
          commands:
            - echo "🏁 Post-build phase complete! All artifacts are ready and verified."
            - echo Build completed on `date`
            - echo Pushing the Docker image...
            - echo 💧
            - echo $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
            - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
            - echo $IMAGE_TAG > image_tag.txt
      artifacts:
        files:
          - image_tag.txt

    EOT
  }

  tags = {
    Environment = "${local.environment}"
  }
}
```

**codebuild-deploy.tf**
```tf
resource "aws_codebuild_project" "deploy" {
  name          = "${local.name}-codebuild-deploy-project"
  description   = "${local.name} Codebuild Deploy Project"
  build_timeout = 5
  service_role  = aws_iam_role.code_build_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_bucket.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
    type                        = "ARM_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group-from-deploy"
      stream_name = "log-stream-from-deploy"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codepipeline_bucket.id}/deploy-log"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      env:
        variables:
          AWS_REGION: "${local.region}"
          S3_BUCKET: ""
          S3_KEY: ""
      phases:
        install:
          commands:
            - echo ✅ Begin install phase
            - aws --version
        pre_build:
          commands:
            - echo 👉 AWS_DEFAULT_REGION $AWS_DEFAULT_REGION
            - IMAGE_TAG=$(cat image_tag.txt)
            - echo 👍 IMAGE_TAG $IMAGE_TAG
            - |
              aws ecs register-task-definition \
                --family ${local.name} \
                --task-role-arn arn:aws:iam::${local.account_id}:role/${local.fargate_ecs_task_role} \
                --execution-role-arn ${local.fargate_ecs_execution_role} \
                --container-definitions '[{
                    "name": "${local.name}",
                    "image": "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/${local.image_repo}:'$IMAGE_TAG'",
                    "memory": 512,
                    "cpu": 256,
                    "essential": true,
                    "portMappings": [
                        {
                            "containerPort": ${local.port},
                            "hostPort": ${local.port},
                            "protocol": "tcp"
                        }
                    ],
                    "environment": [
                        {
                            "name": "MODE_TYPE",
                            "value": "app"
                        },
                        {
                            "name": "AWS_DEFAULT_REGION",
                            "value": "${local.region}"
                        }
                    ],
                    "secrets": ${jsonencode(local.app_secrets)},
                    "ulimits": [
                        {
                            "name": "nofile",
                            "softLimit": 65536,
                            "hardLimit": 65536
                        }
                    ],
                    "logConfiguration": {
                        "logDriver": "awslogs",
                        "options": {
                            "awslogs-group": "${local.env}-${local.project}-${local.app_name}-log-group",
                            "awslogs-region": "${local.region}",
                            "awslogs-stream-prefix": "${local.env}-${local.project}-${local.app_name}-log-stream"
                        }
                    },
                    "healthCheck": {
                        "command": [
                          "CMD-SHELL", 
                          "curl -L -f http://127.0.0.1:${local.port} || exit 1"],
                        "interval": 10,
                        "timeout": 2,
                        "retries": 5
                    },
                    "linuxParameters": {
                        "initProcessEnabled": true
                    }
                }]' \
                --network-mode awsvpc \
                --requires-compatibilities FARGATE \
                --cpu 256 \
                --memory 512 \
                --runtime-platform "{\"cpuArchitecture\": \"ARM64\", \"operatingSystemFamily\": \"LINUX\"}" > ecs-task-definition.json
            - REVISION_NUMBER=$(jq -r '.taskDefinition.revision' ecs-task-definition.json)
        build:
          commands:
            - echo "🚀 Starting build phase..."
            - |
              aws ecs update-service \
                --cluster ${local.ecs_cluster_name} \
                --service ${local.ecs_service_name} \
                --force-new-deployment \
                --task-definition ${local.name}:$REVISION_NUMBER > ecs-service-update.json
        post_build:
          commands:
            - echo "🏁 Post-build phase complete! All artifacts are ready and verified."
            - echo $REVISION_NUMBER > revision_number.txt
      artifacts:
        files:
          - ecs-task-definition.json
          - ecs-service-update.json
          - image_tag.txt 
          - revision_number.txt          
    EOT
  }

  tags = {
    Environment = "${local.environment}"
  }
}
```

**codebuild-iam-policy-and-role.tf**
```tf
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
  name               = "${local.name}-codebuild-role"
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
}```

**codepipeline-iam-policy-and-role.tf**
```tf
data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${local.name}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection",
      "codestar-connections:PassConnection",
      "codestar-connections:GetConnection",
    ]
    resources = [aws_codestarconnections_connection.github_connection.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = [data.aws_kms_alias.s3kmskey.target_key_arn]
  }
}

resource "aws_iam_role_policy" "codepipeline_role_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}
```

**codepipeline.tf**
```tf
resource "aws_codepipeline" "codepipeline" {
  name          = "${local.name}-codepipeline"
  role_arn      = aws_iam_role.codepipeline_role.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

    encryption_key {
      id   = data.aws_kms_alias.s3kmskey.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github_connection.arn
        FullRepositoryId     = "${local.git_repo}"
        BranchName           = "${local.git_branch}"
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "${local.name}-codebuild-build-project"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["build_output"]
      output_artifacts = ["deploy_output"]
      version          = "1"

      configuration = {
        ProjectName = "${local.name}-codebuild-deploy-project"
      }
    }
  }
}
```

**github-connection.tf**
```tf
resource "aws_codestarconnections_connection" "github_connection" {
  name          = "${local.app_name}-${local.env}"
  provider_type = "GitHub"
}```

**kms-key.tf**
```tf
resource "aws_kms_key" "s3kmskey" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "s3kmskey" {
  name          = "alias/${local.name}-kms-key"
  target_key_id = aws_kms_key.s3kmskey.id
}

data "aws_kms_alias" "s3kmskey" {
  name = aws_kms_alias.s3kmskey.name
}```

**local-values.tf**
```tf
locals {
  account_id                 = var.account_id
  project                    = var.project
  environment                = var.env
  env                        = var.env
  app_name                   = var.app_name
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
```

**s3-bucket.tf**
```tf
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${local.name}-codepipeline"
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "random_integer" "rand" {
#   min = 1000000
#   max = 9999999
# }```

**variables-env.tf**
```tf
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

variable "app_name" {
  description = "Application name used in CodePipeline and tagging"
  type        = string
}

variable "app_secrets" {
  description = "List of secret objects with name and valueFrom"
  type        = list(object({
    name      = string
    valueFrom = string
  }))
}


```

