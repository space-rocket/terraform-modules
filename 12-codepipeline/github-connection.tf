resource "aws_codestarconnections_connection" "github_connection" {
  name          = "${local.task_name}-${local.env}"
  provider_type = "GitHub"
}