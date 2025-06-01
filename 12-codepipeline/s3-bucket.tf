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
# }