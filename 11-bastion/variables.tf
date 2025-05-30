variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the instance will be launched"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "my_ip" {
  description = "Your public IP address in CIDR format (e.g., '1.2.3.4/32')"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the Bastion host"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "ssh_key_name" {
  description = "EC2 SSH key pair name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = ""
}
