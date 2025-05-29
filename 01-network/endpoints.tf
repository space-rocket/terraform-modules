# ### SSM
resource "aws_vpc_endpoint" "ssm" {
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.main.id
  security_group_ids  = [aws_security_group.ssm-vpc.id]
  private_dns_enabled = true
  tags = merge(local.common_tags, {
    Name = local.name_prefix
  })
}
resource "aws_vpc_endpoint_subnet_association" "ssm_public" {
  count           = length(aws_subnet.public)
  vpc_endpoint_id = aws_vpc_endpoint.ssm.id
  subnet_id       = element(aws_subnet.public[*].id, count.index)
}