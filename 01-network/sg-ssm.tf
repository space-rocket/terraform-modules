resource "aws_security_group" "ssm-vpc" {
  vpc_id      = aws_vpc.main.id
  name        = "${local.name_prefix}-ssm-vpc"
  description = "Allows HTTPS access to SSM endpoint in VPC"
  lifecycle {
    create_before_destroy = true
  }
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ssm-vpc"
  })
}
### EGRESS
resource "aws_security_group_rule" "ssm_egress" {
  security_group_id = aws_security_group.ssm-vpc.id
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
}
### INGRESS
resource "aws_security_group_rule" "ssm_ingress" {
  security_group_id = aws_security_group.ssm-vpc.id
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  source_security_group_id = aws_security_group.ecs_fargate_task.id
}