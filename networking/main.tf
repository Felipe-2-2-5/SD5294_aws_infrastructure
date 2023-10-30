module "env" {
  source      = "../modules/env"
  environment = var.environment
  project     = var.project

}
data "aws_availability_zones" "available" {}
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}