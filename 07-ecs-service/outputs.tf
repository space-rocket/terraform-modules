output "ecs_service_name" {
  value = aws_ecs_service.ecs_app_service.name
}

output "ecs_task_role_name" {
  value       = aws_iam_role.ecs_task_role.name
  description = "The name of the ECS task role."
}

output "task_name" {
  value       = var.task_name
  description = "The name of the app that this service deploys."
}


