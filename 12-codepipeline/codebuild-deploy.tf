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
            - IMAGE_TAG=$(cat backend_image_tag.txt)
            - echo 👍 IMAGE_TAG $IMAGE_TAG
            - |
              aws ecs register-task-definition \
                --family ${local.name} \
                --task-role-arn arn:aws:iam::${local.account_id}:role/${local.fargate_ecs_task_role} \
                --execution-role-arn ${local.fargate_ecs_execution_role} \
                --container-definitions '[{
                    "name": "${local.app_name}",
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
                    "secrets": [
                      { "name" : "OPENAI_API_KEY", "valueFrom" : "${local.ssm_secret_path_prefix}/OPENAI_API_KEY" },
                      { "name" : "BROKER_ANALYTICS", "valueFrom" : "${local.ssm_secret_path_prefix}/BROKER_ANALYTICS" },
                      { "name" : "DEBUG", "valueFrom" : "${local.ssm_secret_path_prefix}/DEBUG" },
                      { "name" : "CACHING_ENABLED", "valueFrom" : "${local.ssm_secret_path_prefix}/CACHING_ENABLED" },
                      { "name" : "ALLOWED_ORIGINS", "valueFrom" : "${local.ssm_secret_path_prefix}/ALLOWED_ORIGINS" },
                      { "name" : "ALLOWED_METHODS", "valueFrom" : "${local.ssm_secret_path_prefix}/ALLOWED_METHODS" },
                      { "name" : "ALLOWED_HEADERS", "valueFrom" : "${local.ssm_secret_path_prefix}/ALLOWED_HEADERS" },
                      { "name" : "SURREAL_HOST", "valueFrom" : "${local.ssm_secret_path_prefix}/SURREAL_HOST" },
                      { "name" : "SURREAL_NAMESPACE", "valueFrom" : "${local.ssm_secret_path_prefix}/SURREAL_NAMESPACE" },
                      { "name" : "SURREAL_DATABASE", "valueFrom" : "${local.ssm_secret_path_prefix}/SURREAL_DATABASE" },
                      { "name" : "SURREAL_USERNAME", "valueFrom" : "${local.ssm_secret_path_prefix}/SURREAL_USERNAME" },
                      { "name" : "SURREAL_PASSWORD", "valueFrom" : "${local.ssm_secret_path_prefix}/SURREAL_PASSWORD" },
                      { "name" : "CLERK_API_URL", "valueFrom" : "${local.ssm_secret_path_prefix}/CLERK_API_URL" },
                      { "name" : "CLERK_PUBLISHABLE_KEY", "valueFrom" : "${local.ssm_secret_path_prefix}/CLERK_PUBLISHABLE_KEY" }
                    ],
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
          - backend_image_tag.txt 
          - revision_number.txt          
    EOT
  }

  tags = {
    Environment = "${local.environment}"
  }
}
