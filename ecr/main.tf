module "env" {
  source      = "../modules/env"
  environment = var.environment
  project     = var.project

}