resource "aws_opensearch_domain" "this" {
  domain_name    = var.domain_name
  engine_version = var.engine_version

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    zone_awareness_enabled = var.zone_awareness_enabled
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  vpc_options {
    security_group_ids = var.sg_ids
    subnet_ids         = var.subnet_ids
  }

  access_policies = data.aws_iam_policy_document.access.json

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true

    master_user_options {
      master_user_name     = var.admin_name
      master_user_password = var.admin_password
    }
  }

  log_publishing_options {
    enabled                  = true
    log_type                 = "INDEX_SLOW_LOGS"
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.slow_logs.arn
  }

  tags = {
    Name      = var.domain_name
    Env       = var.env
    Project   = var.project
    ManagedBy = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "slow_logs" {
  name              = "/aws/opensearch/${var.domain_name}/slow-logs"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_resource_policy" "opensearch_logs" {
  policy_name = "OpenSearchLogPolicy"
  policy_document = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "es.amazonaws.com"
        },
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ],
        Resource = "${aws_cloudwatch_log_group.slow_logs.arn}:*"
      }
    ]
  })
}

