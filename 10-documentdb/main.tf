resource "aws_docdb_subnet_group" "this" {
  name       = "${var.name_prefix}-docdb-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-docdb-subnet-group"
  })
}

resource "aws_docdb_cluster" "this" {
  cluster_identifier      = "${var.name_prefix}-docdb-cluster"
  master_username         = var.master_username
  master_password         = var.master_password
  engine                  = "docdb"
  engine_version          = var.engine_version
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  db_subnet_group_name    = aws_docdb_subnet_group.this.name
  vpc_security_group_ids  = var.security_group_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-docdb-cluster"
  })
}

resource "aws_docdb_cluster_instance" "this" {
  count              = var.instance_count
  identifier         = "${var.name_prefix}-docdb-instance-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = var.instance_class
  apply_immediately  = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-docdb-instance-${count.index + 1}"
  })
}
