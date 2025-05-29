locals {
  name_prefix = format("%s-%s", var.project, var.env)
  alb_name    = format("%s-%s", local.name_prefix, "alb")

  common_tags = {
    Env       = var.env
    ManagedBy = "terraform"
    Project   = var.project
  }
  # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html#attach-bucket-policy
  lb_account_id = lookup({
    "us-east-1"    = "127311923021"
    "us-east-2"    = "033677994240"
    "us-west-1"    = "027434742980"
    "us-west-2"    = "797873946194"
    },
    var.aws_region
  )
}
