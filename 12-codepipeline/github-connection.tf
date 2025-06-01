resource "aws_codestarconnections_connection" "github_connection" {
  name          = "${local.app_name}-${local.env}"
  provider_type = "GitHub"
}