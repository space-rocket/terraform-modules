locals {
  cluster_identifier = "${var.name_prefix}-docdb-cluster"
}

# Subnet group for DocDB
resource "aws_docdb_subnet_group" "this" {
  name       = "${var.name_prefix}-docdb-subnets"
  subnet_ids = var.subnet_ids
  tags       = merge(var.tags, { Name = "${var.name_prefix}-docdb-subnets" })
}

# Security group for DocDB
resource "aws_security_group" "docdb" {
  name        = "${var.name_prefix}-docdb-sg"
  description = "DocDB access"
  vpc_id      = var.vpc_id

  # Egress all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-docdb-sg" })
}

# Allow 27017 from allowed SGs
resource "aws_security_group_rule" "from_allowed_sgs" {
  for_each                 = toset(var.allowed_sg_ids)
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  security_group_id        = aws_security_group.docdb.id
  source_security_group_id = each.value
  description              = "Allow from SG ${each.value} to DocDB 27017"
}

# Allow 27017 from CIDRs if any
resource "aws_security_group_rule" "from_allowed_cidrs" {
  count             = length(var.allowed_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  security_group_id = aws_security_group.docdb.id
  cidr_blocks       = var.allowed_cidr_blocks
  description       = "Allow from CIDR blocks to DocDB 27017"
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
  vpc_security_group_ids  = [aws_security_group.docdb.id]

  tags = merge(var.tags, { Name = local.cluster_identifier })
}

# Restore from snapshot if snapshot_identifier is set
resource "aws_docdb_cluster" "restore" {
  count                 = var.snapshot_identifier != null ? 1 : 0
  cluster_identifier    = local.cluster_identifier
  engine                = "docdb"
  snapshot_identifier   = var.snapshot_identifier
  db_subnet_group_name  = aws_docdb_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.docdb.id]

  tags = merge(var.tags, { Name = local.cluster_identifier })
}

# Choose active cluster values
locals {
  active_cluster_id       = try(aws_docdb_cluster.fresh[0].id, aws_docdb_cluster.restore[0].id)
  active_cluster_endpoint = try(aws_docdb_cluster.fresh[0].endpoint, aws_docdb_cluster.restore[0].endpoint)
  active_reader_endpoint  = try(aws_docdb_cluster.fresh[0].reader_endpoint, aws_docdb_cluster.restore[0].reader_endpoint)
}

resource "aws_docdb_cluster_instance" "this" {
  count              = var.instance_count
  identifier         = "${local.active_cluster_id}-${count.index + 1}"
  cluster_identifier = local.active_cluster_id
  instance_class     = var.instance_class
  apply_immediately  = true

  tags = merge(var.tags, { Name = "${local.active_cluster_id}-${count.index + 1}" })
}
