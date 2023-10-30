module "env" {
  source      = "../modules/env"
  environment = var.environment
  project     = var.project
}
data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}