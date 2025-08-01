resource "aws_iam_policy" "ec2_instance_s3_seed_policy" {
  name = "${var.instance_name}-AllowS3DocdbSeedRead"

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
