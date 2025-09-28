locals {
  cluster_identifier = "${var.name_prefix}-docdb-cluster"
}

# Fresh create if no snapshot
resource "aws_docdb_cluster" "fresh" {
  count                   = var.snapshot_identifier == null ? 1 : 0
  cluster_identifier      = local.cluster_identifier
  master_username         = var.master_username
  master_password         = var.master_password
  engine                  = "docdb"
  engine_version          = var.engine_version
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  db_subnet_group_name    = aws_docdb_subnet_group.this.name
  vpc_security_group_ids  = var.security_group_ids

  tags = merge(var.tags, {
    Name = local.cluster_identifier
  })
}

# Restore from snapshot if snapshot_identifier is set
resource "aws_docdb_cluster" "restore" {
  count                  = var.snapshot_identifier != null ? 1 : 0
  cluster_identifier     = local.cluster_identifier
  engine                 = "docdb"
  snapshot_identifier    = var.snapshot_identifier
  db_subnet_group_name   = aws_docdb_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids

  tags = merge(var.tags, {
    Name = local.cluster_identifier
  })
}

# Pick whichever cluster got created
locals {
  active_cluster_id      = try(aws_docdb_cluster.fresh[0].id, aws_docdb_cluster.restore[0].id)
  active_cluster_endpoint = try(aws_docdb_cluster.fresh[0].endpoint, aws_docdb_cluster.restore[0].endpoint)
  active_reader_endpoint  = try(aws_docdb_cluster.fresh[0].reader_endpoint, aws_docdb_cluster.restore[0].reader_endpoint)
}

resource "aws_docdb_cluster_instance" "this" {
  count              = var.instance_count
  identifier         = "${local.active_cluster_id}-${count.index + 1}"
  cluster_identifier = local.active_cluster_id
  instance_class     = var.instance_class
  apply_immediately  = true

  tags = merge(var.tags, {
    Name = "${local.active_cluster_id}-${count.index + 1}"
  })
}
