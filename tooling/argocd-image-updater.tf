# manifest secret for argo cd
resource "kubernetes_manifest" "argocd_secret" {
  manifest = yamldecode(templatefile("${path.module}/templates/argocd/secret.yaml", {
    GITHUB_URL   = base64encode("https://github.com/letrung910/sd5294_msa_gitops")
    GITHUB_TOKEN = local.secrets
    NAMESPACE    = "argocd"
  }))
  depends_on = [
    helm_release.argocd,
  ]

}

data "aws_iam_policy_document" "ecr" {
  statement {
    sid    = replace("EKS-argocd-image-updater-${var.environment}", "-", "")
    effect = "Allow"

    # access list & read
    actions = [
      "ecr:GetRegistryPolicy",
      "ecr:DescribeImageScanFindings",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRegistry",
      "ecr:DescribePullThroughCacheRules",
      "ecr:DescribeImageReplicationStatus",
      "ecr:GetAuthorizationToken",
      "ecr:ListTagsForResource",
      "ecr:ListImages",
      "ecr:BatchGetRepositoryScanningConfiguration",
      "ecr:GetRegistryScanningConfiguration",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetRepositoryPolicy",
      "ecr:GetLifecyclePolicy"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr" {
  name        = "EKS-argocd-image-updater-${var.environment}"
  description = "EKS cluster-autoscaler policy for cluster EKS-argocd-image-updater-${var.environment}"
  policy      = data.aws_iam_policy_document.ecr.json
}

module "iam_assumable_role_ecr" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "EKS-argocd-image-updater-${var.environment}"

  role_policy_arns = {
    policy = aws_iam_policy.ecr.arn
  }

  oidc_providers = {
    one = {
      provider_arn               = data.terraform_remote_state.eks.outputs.oidc_provider_arn
      namespace_service_accounts = ["argocd:argocd-image-updater"]
    }
  }
}

# helm for argo cd image updater
resource "helm_release" "argocd_image_updater" {
  name             = "argocd-image-updater"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-image-updater"
  version    = "0.9.1"

  depends_on = [
    helm_release.argocd,
  ]

  values = [
    templatefile("${path.module}/templates/argocd/image-updater-values.yaml", {
      ARGOCD_IMAGE_UPDATER_ROLE_ARN = module.iam_assumable_role_ecr.iam_role_arn
    })
  ]
}