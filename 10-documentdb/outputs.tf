output "cluster_endpoint" {
  description = "DocumentDB cluster writer endpoint"
  value       = local.active_cluster_endpoint
}

output "reader_endpoint" {
  description = "DocumentDB reader endpoint"
  value       = local.active_reader_endpoint
}

output "cluster_id" {
  description = "DocumentDB cluster ID"
  value       = local.active_cluster_id
}

output "security_group_id" {
  description = "Security group created for DocDB"
  value       = aws_security_group.docdb.id
}

output "master_username" {
  description = "Master username when creating fresh"
  value       = var.master_username
}

output "master_password" {
  description = "Master password when creating fresh"
  value       = var.master_password
  sensitive   = true
}
