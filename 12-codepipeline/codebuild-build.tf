resource "aws_codebuild_project" "build" {
  name          = "${local.task_name}"
  description   = "${local.task_name} Codebuild Build Project"
  build_timeout = 15
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

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = local.image_repo
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${local.log_group_name}/codebuild/build"
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
            - echo Installing Docker Buildx...
            - docker buildx create --use
            - docker buildx inspect --bootstrap
        pre_build:
          commands:
            - echo 👉 AWS_DEFAULT_REGION $AWS_DEFAULT_REGION
            - echo 👉 AWS_ACCOUNT_ID $AWS_ACCOUNT_ID
            - echo 👉 IMAGE_REPO_NAME $IMAGE_REPO_NAME
            - echo 👉 COMMIT_ID $CODEBUILD_RESOLVED_SOURCE_VERSION
            - export IMAGE_TAG=$CODEBUILD_RESOLVED_SOURCE_VERSION
            - echo 👉 IMAGE_TAG $IMAGE_TAG
            - echo 🔍 Detecting system architecture...
            - |
              ARCH=$(uname -m)
              if [ "$ARCH" = "aarch64" ]; then
                export DOCKER_PLATFORM="linux/arm64"
              else
                export DOCKER_PLATFORM="linux/amd64"
              fi
            - echo 🧠 Target Docker Platform: $DOCKER_PLATFORM
            - echo 🔐 Logging in to Amazon ECR...
            - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
        build:
          commands:
            - echo "🚀 Starting build phase..."
            - docker buildx build --platform $DOCKER_PLATFORM -t $IMAGE_REPO_NAME:$IMAGE_TAG --push .
        post_build:
          commands:
            - echo "🏁 Post-build phase complete!"
            - echo ✅ Build completed on `date`
            - echo 💧 Image: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
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
