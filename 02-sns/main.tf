# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.21"
#     }
#   }

#   required_version = "~> 1.6"
# }

# provider "aws" {
#   default_tags {
#     tags = local.common_tags
#   }
#   region = var.aws_region
# }
