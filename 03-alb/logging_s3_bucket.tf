resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = var.logs_bucket == null ? 0 : 1

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# resource "aws_s3_bucket_lifecycle_configuration" "logs" {
#   count = var.logs_bucket == null ? 0 : 1

#   bucket = aws_s3_bucket.logs[0].id

#   rule {
#     id      = "delete"
#     status  = "Enabled"

#     expiration {
#       days = var.logs_expiration
#     }
#   }
# }

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = var.logs_bucket == null ? 0 : 1

  bucket = aws_s3_bucket.logs[0].id

  rule {
    id      = "delete"
    status  = "Enabled"

    filter {
      prefix = "${var.logs_prefix}/AWSLogs/${var.account_id}/"
    }

    expiration {
      days = var.logs_expiration
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count  = var.logs_bucket == null ? 0 : 1
  bucket = aws_s3_bucket.logs[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket" "logs" {
  count = var.logs_bucket == null ? 0 : 1

  bucket = var.logs_bucket

  force_destroy = var.logs_bucket_force_destroy

  tags = local.common_tags
}

data "aws_iam_policy_document" "alb_logs_s3" {
  count = var.logs_bucket == null ? 0 : 1

  # statement {
  #   sid    = "AllowALBLogDeliveryPut"
  #   effect = "Allow"

  #   principals {
  #     type        = "Service"
  #     identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
  #   }

  #   actions = ["s3:PutObject"]
  #   resources = [
  #     "${aws_s3_bucket.logs[0].arn}/${var.logs_prefix}/AWSLogs/${var.account_id}/*"
  #   ]

  #   condition {
  #     test     = "StringEquals"
  #     variable = "s3:x-amz-acl"
  #     values   = ["bucket-owner-full-control"]
  #   }
  # }

  # REPLACE your current "AllowALBLogDeliveryPut" with this minimal block
  statement {
    sid    = "AllowALBLogDeliveryPut"
    effect = "Allow"

    principal {
      type        = "AWS"
      identifiers = ["arn:aws:iam::127311923021:root"] # us-east-1 ELB account
    }

    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.logs[0].arn}/${var.logs_prefix}/AWSLogs/${var.account_id}/*"
    ]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:elasticloadbalancing:${var.aws_region}:${var.account_id}:loadbalancer/*"]
    }
  }

  statement {
    sid    = "AllowALBLogDeliveryGetAcl"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs[0].arn]
  }

  statement {
    sid    = "AllowBucketOwnerFullControl"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.account_id]
    }

    actions   = [
      "s3:PutObject",
      "s3:GetObject"
    ] 
    resources = [
      "${aws_s3_bucket.logs[0].arn}/${var.logs_prefix}/AWSLogs/${var.account_id}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count = var.logs_bucket == null ? 0 : 1

  bucket = aws_s3_bucket.logs[0].id
  policy = data.aws_iam_policy_document.alb_logs_s3[0].json
}
