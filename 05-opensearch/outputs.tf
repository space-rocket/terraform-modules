output "domain_endpoint" {
  value = aws_opensearch_domain.this.endpoint
}

output "domain_arn" {
  value = aws_opensearch_domain.this.arn
}

output "domain_name" {
  value = aws_opensearch_domain.this.domain_name
}

output "snapshot_role_arn" {
  description = "IAM role ARN that OpenSearch uses to access the snapshot S3 bucket"
  value       = aws_iam_role.snapshot_access.arn
}

output "snapshot_policy_arn" {
  description = "IAM policy ARN attached to the snapshot role"
  value       = aws_iam_policy.snapshot_access.arn
}

output "security_group_ids" {
  value = var.sg_ids
}

