resource "aws_kms_key" "s3kmskey" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "s3kmskey" {
  name          = "alias/${local.task_name}-kms-key"
  target_key_id = aws_kms_key.s3kmskey.id
}

data "aws_kms_alias" "s3kmskey" {
  name = aws_kms_alias.s3kmskey.name
}