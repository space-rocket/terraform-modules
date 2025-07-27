resource "aws_iam_policy" "bastion_s3_seed_policy" {
  name = "${var.name_prefix}-AllowS3DocdbSeedRead"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "arn:aws:s3:::${var.env}-${var.project}-seed-bucket/*"
      }
    ]
  })
}
