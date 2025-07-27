output "ec2_instance_public_ip" {
  description = "Public IP address of the ec2_instance host"
  value       = aws_instance.ec2_instance.public_ip
}

output "ec2_instance_instance_id" {
  description = "ID of the ec2_instance host instance"
  value       = aws_instance.ec2_instance.id
}
