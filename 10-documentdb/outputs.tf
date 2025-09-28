output "cluster_endpoint" {
  description = "DocumentDB cluster writer endpoint"
  value       = local.endpoint
}

output "reader_endpoint" {
  description = "DocumentDB reader endpoint"
  value       = local.reader_endpoint
}

output "cluster_id" {
  description = "DocumentDB cluster ID"
  value       = local.cluster_id
}

output "security_group_id" {
  description = "Security group created for DocDB"
  value       = aws_security_group.docdb.id
}

# These are meaningful only when creating fresh
output "master_username" {
  description = "Master username (fresh create path)"
  value       = var.master_username
}

output "master_password" {
  description = "Master password (fresh create path)"
  value       = var.master_password
  sensitive   = true
}
