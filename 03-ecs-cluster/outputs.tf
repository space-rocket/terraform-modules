output "ecs_cluster_id" {
  value = aws_ecs_cluster.ecs_app_cluster.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_app_cluster.name
}

output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution_role.arn
}
