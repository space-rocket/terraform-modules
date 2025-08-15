resource "aws_security_group" "ec2_instance" {
  name        = "${var.instance_name}-ec2_instance-sg"
  description = "Allow SSH from my IP"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH access from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_instance" "ec2_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = element(var.subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.ec2_instance.id]
  key_name               = var.key_name

  associate_public_ip_address = true
  user_data                   = var.user_data

  root_block_device {
    volume_size = var.root_volume_size_gb
    volume_type = var.root_volume_type
  }
  
  tags = merge(var.tags, {
    Name = "${var.instance_name}-ec2_instance"
  })
}
