resource "aws_codestarconnections_connection" "github_connection" {
  name          = "${local.task_name}"
  provider_type = "GitHub"
}