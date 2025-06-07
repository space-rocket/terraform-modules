data "aws_iam_policy_document" "access" {
  statement {
    sid    = "AllowMacAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "es:*"
    ]

    resources = [
      "arn:aws:es:${var.aws_region}:${var.account_id}:domain/${var.domain_name}/*"
    ]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["${var.my_ip}/32"]
    }
  }
}
