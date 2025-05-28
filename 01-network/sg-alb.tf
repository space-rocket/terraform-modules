resource "aws_security_group" "alb" {
  description = "Alb ${upper(var.env)}"
  # name        = "Alb ${upper(var.env)}"
  name        = "${var.project}-alb"
  vpc_id      = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
  })
}

### EGRESS

resource "aws_security_group_rule" "alb_egress" {
  description = "Alb ${upper(var.env)} Egress"
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "all"

  cidr_blocks       = ["0.0.0.0/0"] # tfsec:ignore:AWS007
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress_v6" {
  description = "Alb ${upper(var.env)} Egress"
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "all"

  ipv6_cidr_blocks  = ["::/0"] # tfsec:ignore:AWS007
  security_group_id = aws_security_group.alb.id
}

### ICMP

resource "aws_security_group_rule" "alb_icmp" {
  description = "Alb ${upper(var.env)} ICMP"
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"

  cidr_blocks       = ["0.0.0.0/0"] # tfsec:ignore:AWS006
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_icmp_v6" {
  description = "Alb ${upper(var.env)} ICMP"
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmpv6"

  ipv6_cidr_blocks  = ["::/0"] # tfsec:ignore:AWS006
  security_group_id = aws_security_group.alb.id
}

### FROM PUBLIC IPS
resource "aws_security_group_rule" "alb_80" {
  count = length(var.public_ips)

  description = values(var.public_ips)[count.index]
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = [keys(var.public_ips)[count.index]]

  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_443" {
  count = length(var.public_ips)

  description = values(var.public_ips)[count.index]
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = [keys(var.public_ips)[count.index]]

  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_80_v6" {
  count = length(var.public_ips_v6)

  description      = values(var.public_ips)[count.index]
  type             = "ingress"
  from_port        = 80
  to_port          = 80
  protocol         = "tcp"
  ipv6_cidr_blocks = [keys(var.public_ips_v6)[count.index]]

  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_443_v6" {
  count = length(var.public_ips_v6)

  description      = values(var.public_ips)[count.index]
  type             = "ingress"
  from_port        = 443
  to_port          = 443
  protocol         = "tcp"
  ipv6_cidr_blocks = [keys(var.public_ips_v6)[count.index]]

  security_group_id = aws_security_group.alb.id
}
