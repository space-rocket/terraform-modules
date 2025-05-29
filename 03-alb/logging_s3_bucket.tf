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

###############################################################################
# Bucket policy that lets an Application Load Balancer in us-west-2
# write access logs into the <logs bucket>/<prefix>/AWSLogs/<account-id>/… key-space
###############################################################################
data "aws_elb_service_account" "this" {}  # resolves the regional ELB acct-ID

data "aws_iam_policy_document" "alb_logs_s3" {
  count = var.logs_bucket == null ? 0 : 1

  ########################################
  # 1. Service principal — PUT *and* GET-ACL
  ########################################
  # ALB’s new log-delivery service principal
  statement {
    sid    = "AllowALBLogDeliveryPut"           # UPDATED
    effect = "Allow"

    principals {                                # UPDATED principal
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.logs[0].arn}/${var.logs_prefix}/AWSLogs/${var.account_id}/*"
    ]

    # ALB always sets this canned ACL
    condition {                                 # UPDATED
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {                                   # NEW – service principal needs ACL read
    sid    = "AllowALBLogDeliveryGetAcl"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs[0].arn]
  }

  ########################################
  # 2. Regional ELB *account-root* principal
  ########################################
  # Older ALBs (and many in us-west-2) still use the regional account ID.
  # Grant both PUT and GET-ACL to be safe.
  statement {                                   # UPDATED
    sid    = "AllowRegionalELBPut"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.this.arn]  # e.g. arn:aws:iam::797873946194:root
    }

    actions   = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.logs[0].arn}/${var.logs_prefix}/AWSLogs/${var.account_id}/*"
    ]
  }

  statement {                                   # NEW – regional account needs ACL read
    sid    = "AllowRegionalELBGetAcl"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.this.arn]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs[0].arn]
  }
}


resource "aws_s3_bucket_policy" "alb_logs" {
  count = var.logs_bucket == null ? 0 : 1

  bucket = aws_s3_bucket.logs[0].id
  policy = data.aws_iam_policy_document.alb_logs_s3[0].json
}
