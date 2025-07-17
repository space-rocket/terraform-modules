resource "aws_codebuild_project" "deploy" {
  name          = "${local.task_name}-codebuild-deploy-project"
  description   = "${local.task_name} Codebuild Deploy Project"
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
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
    type                        = local.codebuild_container_type
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${local.log_group_name}/codebuild/deploy"
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
                --family "${local.task_name}" \
                --task-role-arn arn:aws:iam::${local.account_id}:role/${local.fargate_ecs_task_role} \
                --execution-role-arn ${local.fargate_ecs_execution_role} \
                --container-definitions '[{
                    "name": "${local.task_name}",
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
                            "awslogs-group": "${local.log_group_name}/codebuild/deploy",
                            "awslogs-region": "${local.region}",
                            "awslogs-stream-prefix": "api"
                        }
                    },
                    "healthCheck": {
                        "command": ["CMD-SHELL", "curl -f http://localhost:${local.port}/health || exit 1"],
                        "interval": 60,
                        "timeout": 10,
                        "retries": 3
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
                --task-definition ${local.task_name}:$REVISION_NUMBER > ecs-service-update.json
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
