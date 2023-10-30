resource "helm_release" "argocd_rollouts" {
  name             = "argocd-rollouts"
  namespace        = "argocd-rollouts"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = "2.32.0"

  values = [
    templatefile("${path.module}/templates/argocd/argocd-rollouts.yaml", {}),
  ]
}