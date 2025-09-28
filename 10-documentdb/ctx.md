**.tool-versions**
```
terraform 1.11.3

```

**ctx.md**
```markdown
**.tool-versions**
```
terraform 1.11.3

```

**ctx.md**
```markdown

```

**issue.md**
```markdown
**main.tf**
```tf
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
```

**outputs.tf**
```tf
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
```

**variables.tf**
```tf
variable "name_prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of VPC security group IDs"
  type        = list(string)
}

variable "master_username" {
  description = "Master username for DocumentDB"
  type        = string
}

variable "master_password" {
  description = "Master password for DocumentDB"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "Instance class for DocumentDB instances"
  type        = string
  default     = "db.t3.medium"
}

variable "instance_count" {
  description = "Number of DocumentDB instances"
  type        = number
  default     = 1
}

variable "engine_version" {
  description = "Version of DocumentDB engine"
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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```


```

**issue.sh**
```bash
#!/bin/bash

# Define the output file
output_file="issue.md"

# Clear the output file if it already exists
> "$output_file"

# Loop through .tf files in the current directory
for file in *.tf; do
  if [ -f "$file" ]; then
    # Write the file name to the output file
    echo "**$file**" >> "$output_file"
    
    # Write the code block with cat contents to the output file
    echo '```tf' >> "$output_file"
    cat "$file" >> "$output_file"
    echo '```' >> "$output_file"
    
    # Add a newline to separate the sections
    echo >> "$output_file"
  fi
done

# Append content from all .tfvars files with the same formatting
for tfvars_file in *.tfvars; do
  if [ -f "$tfvars_file" ]; then
    # Write the file name to the output file
    echo "**$tfvars_file**" >> "$output_file"
    
    # Write the code block with cat contents to the output file
    echo '```tf' >> "$output_file"
    cat "$tfvars_file" >> "$output_file"
    echo '```' >> "$output_file"
    
    # Add a newline to separate the sections
    echo >> "$output_file"
  fi
done

echo "Done! Check $output_file for the results."

```

**main.tf**
```hcl
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

```

**outputs.tf**
```hcl
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

```

**variables.tf**
```hcl
variable "name_prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of VPC security group IDs"
  type        = list(string)
}

variable "master_username" {
  description = "Master username for DocumentDB"
  type        = string
}

variable "master_password" {
  description = "Master password for DocumentDB"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "Instance class for DocumentDB instances"
  type        = string
  default     = "db.t3.medium"
}

variable "instance_count" {
  description = "Number of DocumentDB instances"
  type        = number
  default     = 1
}

variable "engine_version" {
  description = "Version of DocumentDB engine"
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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

```

