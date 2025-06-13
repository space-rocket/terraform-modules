output "domain_id" {
  value       = aws_sagemaker_domain.this.id
  description = "SageMaker Domain ID"
}

output "url" {
  value       = aws_sagemaker_domain.this.url
  description = "Studio access URL"
}

output "user_profile_name" {
  value       = aws_sagemaker_user_profile.this.user_profile_name
  description = "User Profile Name"
}

output "execution_role_arn" {
  value       = var.execution_role_arn
  description = "Execution Role ARN used by the domain"
}
