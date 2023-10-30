data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "${var.project}-${var.environment}-tfstate"
    key    = "${var.environment}/networking/terraform.tfstate"
    region = "us-east-1"
  }
}
