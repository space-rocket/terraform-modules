output "cluster_endpoint" {
  description = "DocumentDB cluster endpoint"
  value       = aws_docdb_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "DocumentDB reader endpoint"
  value       = aws_docdb_cluster.this.reader_endpoint
}

output "cluster_id" {
  description = "DocumentDB cluster ID"
  value       = aws_docdb_cluster.this.id
}

output "master_username" {
  description = "DocumentDB master username"
  value       = var.master_username
}

output "master_password" {
  description = "DocumentDB master password"
  value       = var.master_password
  sensitive   = true
}
