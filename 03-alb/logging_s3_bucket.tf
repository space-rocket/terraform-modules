resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = var.logs_bucket == null ? 0 : 1

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = var.logs_bucket == null ? 0 : 1

  bucket = aws_s3_bucket.logs[0].id

  rule {
    id      = "delete"
    status  = "Enabled"

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

  statement {
    sid = "AlbS301"

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs[0].arn}/${var.logs_prefix}/AWSLogs/${var.account_id}/*"]

    principals {
      # identifiers = ["arn:aws:iam::${local.lb_account_id}:root"]
      identifiers = ["elasticloadbalancing.amazonaws.com"]
      type        = "AWS"
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid = "AlbS302"

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs[0].arn}/${var.logs_prefix}/AWSLogs/${var.account_id}/*"]

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    sid = "AlbS303"

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs[0].arn]

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    sid = "AllowALBAccess"

    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.logs[0].arn}/${var.logs_prefix}/AWSLogs/${var.account_id}/*"
    ]

    principals {
      identifiers = ["elasticloadbalancing.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    sid = "AllowLogsDelivery"
    actions = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs[0].arn}/${var.logs_prefix}/AWSLogs/${var.account_id}/*"]

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid       = "ALBGetBucketAcl"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs[0].arn]
    principals {
      identifiers = ["elasticloadbalancing.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count = var.logs_bucket == null ? 0 : 1

  bucket = aws_s3_bucket.logs[0].id
  policy = data.aws_iam_policy_document.alb_logs_s3[0].json
}
