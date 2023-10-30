data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "${var.project}-${var.environment}-tfstate"
    key    = "${var.environment}/eks-cluster/terraform.tfstate"
    region = "us-east-1"
  }
}


data "terraform_remote_state" "common" {
  backend = "s3"
  config = {
    bucket = "${var.project}-${var.environment}-tfstate"
    key    = "${var.environment}/common/terraform.tfstate"
    region = "us-east-1"
  }
}