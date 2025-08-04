resource "aws_codepipeline" "codepipeline" {
  name          = "${local.task_name}-codepipeline"
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
        ProjectName = "${local.task_name}"
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
        ProjectName = "${local.task_name}-codebuild-deploy-project"
      }
    }
  }
}

resource "aws_cloudwatch_event_rule" "pipeline_events" {
  name        = "${local.task_name}-pipeline-events"
  description = "Capture CodePipeline execution state changes"
  event_pattern = jsonencode({
    source = ["aws.codepipeline"],
    detail-type = ["CodePipeline Pipeline Execution State Change"],
    detail = {
      pipeline = [aws_codepipeline.codepipeline.name]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.pipeline_events.name
  arn       = var.sns_topic_arn
}

