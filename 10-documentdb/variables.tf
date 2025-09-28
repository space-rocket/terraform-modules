variable "name_prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC where DocDB will live"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)
  nullable    = false
}

# Security groups that are allowed to connect to DocDB:27017
variable "allowed_sg_ids" {
  description = "List of SG IDs that can reach DocDB on 27017"
  type        = list(string)
  default     = []
}

# Optional CIDRs allow-list
variable "allowed_cidr_blocks" {
  description = "Optional CIDR blocks that can reach DocDB on 27017"
  type        = list(string)
  default     = []
}

# Credentials used only when creating a fresh cluster (ignored on restore)
variable "master_username" {
  description = "Master username for DocumentDB (fresh create only)"
  type        = string
  default     = "docdbadmin"
}

variable "master_password" {
  description = "Master password for DocumentDB (fresh create only)"
  type        = string
  sensitive   = true
  default     = null
}

variable "instance_class" {
  description = "Instance class for DocumentDB instances"
  type        = string
  default     = "db.r6g.large"
}

variable "instance_count" {
  description = "Number of DocumentDB instances"
  type        = number
  default     = 1
}

variable "engine_version" {
  description = "Version of DocumentDB engine (fresh create only)"
  type        = string
  default     = "4.0.0"
}

variable "backup_retention_period" {
  description = "Days to retain backups"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Daily time range during which backups are created"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Weekly maintenance window"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "deletion_protection" {
  description = "Protect cluster from deletion"
  type        = bool
  default     = true
}

# Restore from snapshot
variable "snapshot_identifier" {
  description = "If set, restore the cluster from this snapshot"
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "KMS key for storage encryption. Null to use default"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
