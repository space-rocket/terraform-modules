output "vpc" {
  value = aws_vpc.main
}

output "subnets_private" {
  value = aws_subnet.private
}

output "subnets_public" {
  value = aws_subnet.public
}

output "sg_alb" {
  value = aws_security_group.alb
}

output "sg_ecs_fargate_task" {
  value = aws_security_group.ecs_fargate_task
}