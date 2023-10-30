
data "aws_caller_identity" "current" {}
locals {
  eks_name        = "${var.project}-${var.environment}-cluster"
  cluster_version = "1.27"
  region          = "us-east-1"
  tags = {
    environment = "${var.environment}"
    project     = "${var.project}"
  }

  common_tags = {
    DeployedBy = "trunglv"
  }
  account_id = data.aws_caller_identity.current.account_id

  env_common = yamldecode(file("${path.module}/config/${var.environment}.yaml"))

}