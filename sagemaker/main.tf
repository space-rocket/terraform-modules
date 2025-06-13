resource "aws_sagemaker_domain" "this" {
  domain_name = var.domain_name
  auth_mode   = "IAM"
  subnet_ids  = var.subnet_ids
  vpc_id      = var.vpc_id

  default_user_settings {
    execution_role = var.execution_role_arn
  }

  tags = var.tags
}


resource "aws_sagemaker_user_profile" "this" {
  domain_id         = aws_sagemaker_domain.this.id
  user_profile_name = var.user_profile_name
  tags              = var.tags
}
