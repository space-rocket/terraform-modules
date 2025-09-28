terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  cluster_name = "${var.name_prefix}-docdb-cluster"
}

# Subnet group
resource "aws_docdb_subnet_group" "this" {
  name       = "${var.name_prefix}-docdb-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = merge(var.tags, { Name = "${var.name_prefix}-docdb-subnet-group" })
}

# Security group owned by the DocDB cluster
resource "aws_security_group" "docdb" {
  name        = "${var.name_prefix}-docdb-sg"
  description = "DocDB inbound from app"
  vpc_id      = data.aws_subnet.example.vpc_id # placeholder, see data sources below
  tags        = merge(var.tags, { Name = "${var.name_prefix}-docdb-sg" })
}

# Derive VPC id from first subnet (safe since all subnets must be in same VPC)
data "aws_subnet" "example" {
  id = var.subnet_ids[0]
}

# Ingress from SGs
resource "aws_security_group_rule" "from_sgs" {
  for_each                 = toset(var.allowed_sg_ids)
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  security_group_id        = aws_security_group.docdb.id
  source_security_group_id = each.key
}

# Optional ingress from CIDRs
resource "aws_security_group_rule" "from_cidrs" {
  count             = length(var.allowed_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  security_group_id = aws_security_group.docdb.id
  cidr_blocks       = var.allowed_cidr_blocks
}

# Egress allow all for return traffic
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.docdb.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = []
}

# Cluster when creating fresh
resource "aws_docdb_cluster" "fresh" {
  count                           = var.snapshot_identifier == null ? 1 : 0
  cluster_identifier              = local.cluster_name
  engine                          = "docdb"
  engine_version                  = var.engine_version
  master_username                 = var.master_username
  master_password                 = var.master_password
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  db_subnet_group_name            = aws_docdb_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.docdb.id]
  storage_encrypted               = true
  kms_key_id                      = var.kms_key_id
  deletion_protection             = var.deletion_protection
  apply_immediately               = true
  tags                            = merge(var.tags, { Name = local.cluster_name })
}

# Cluster when restoring from snapshot
resource "aws_docdb_cluster" "restore" {
  count                           = var.snapshot_identifier != null ? 1 : 0
  cluster_identifier              = local.cluster_name
  engine                          = "docdb"
  snapshot_identifier             = var.snapshot_identifier
  db_subnet_group_name            = aws_docdb_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.docdb.id]
  storage_encrypted               = true
  kms_key_id                      = var.kms_key_id
  preferred_maintenance_window    = var.preferred_maintenance_window
  deletion_protection             = var.deletion_protection
  apply_immediately               = true
  tags                            = merge(var.tags, { Name = local.cluster_name })
}

# Choose active cluster outputs
locals {
  cluster_id       = try(aws_docdb_cluster.fresh[0].id, aws_docdb_cluster.restore[0].id)
  endpoint         = try(aws_docdb_cluster.fresh[0].endpoint, aws_docdb_cluster.restore[0].endpoint)
  reader_endpoint  = try(aws_docdb_cluster.fresh[0].reader_endpoint, aws_docdb_cluster.restore[0].reader_endpoint)
}

# Create instances
resource "aws_docdb_cluster_instance" "this" {
  count              = var.instance_count
  identifier         = "${local.cluster_id}-${count.index + 1}"
  cluster_identifier = local.cluster_id
  instance_class     = var.instance_class
  engine             = "docdb"
  apply_immediately  = true
  tags               = merge(var.tags, { Name = "${local.cluster_id}-${count.index + 1}" })
}
