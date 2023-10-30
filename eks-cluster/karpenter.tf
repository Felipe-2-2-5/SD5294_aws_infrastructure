
# ### karpenter
# module "karpenter" {
#   source = "terraform-aws-modules/eks/aws//modules/karpenter"

#   cluster_name                    = module.eks.cluster_name
#   irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
#   irsa_namespace_service_accounts = ["karpenter:karpenter"]

#   iam_role_additional_policies = {
#     AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   }

#   tags = merge(module.env.tags, {
#     "Terraform" = "True"
#   })
# }

# resource "helm_release" "karpenter" {
#   namespace        = "karpenter"
#   create_namespace = true

#   name                = "karpenter"
#   repository          = "oci://public.ecr.aws/karpenter"
#   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
#   repository_password = data.aws_ecrpublic_authorization_token.token.password
#   chart               = "karpenter"
#   version             = "v0.21.1"

#   set {
#     name  = "settings.aws.clusterName"
#     value = module.eks.cluster_name
#   }

#   set {
#     name  = "settings.aws.clusterEndpoint"
#     value = module.eks.cluster_endpoint
#   }

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = module.karpenter.irsa_arn
#   }

#   set {
#     name  = "settings.aws.defaultInstanceProfile"
#     value = module.karpenter.instance_profile_name
#   }

#   set {
#     name  = "settings.aws.interruptionQueueName"
#     value = module.karpenter.queue_name
#   }
# }

# resource "kubectl_manifest" "karpenter_provisioner" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.sh/v1alpha5
#     kind: Provisioner
#     metadata:
#       name: "${var.project}-${var.environment}-karpenter"
#     spec:
#       requirements:
#         - key: kubernetes.io/arch
#           operator: In
#           values: ["amd64"]
#         - key: kubernetes.io/os
#           operator: In
#           values: ["linux"]
#         - key: karpenter.sh/capacity-type
#           operator: In
#           values: ["spot"]
#         - key: karpenter.k8s.aws/instance-size
#           operator: In
#           values: ["t3.medium","t3.large", "c5.large", "c5.xlarge"]
#         - key: karpenter.k8s.aws/instance-family
#           operator: In
#           values:
#           - t3
#           - t3a
#           - m5
#           - c5
#       limits:
#         resources:
#           cpu: 1000
#           memory: 20Gi
#       providerRef:
#         name: default
#       taints:
#         - key: dedicated
#           value: app
#           effect: NoSchedule
#       ttlSecondsAfterEmpty: 30
#   YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }

# resource "kubectl_manifest" "karpenter_provisioner1" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.sh/v1alpha5
#     kind: Provisioner
#     metadata:
#       name: "${var.project}-${var.environment}-karpenter1"
#     spec:
#       requirements:
#         - key: kubernetes.io/arch
#           operator: In
#           values: ["amd64"]
#         - key: kubernetes.io/os
#           operator: In
#           values: ["linux"]
#         - key: karpenter.sh/capacity-type
#           operator: In
#           values: ["spot"]
#         - key: karpenter.k8s.aws/instance-size
#           operator: In
#           values: ["t3.medium","t3.large", "c5.large", "c5.xlarge"]
#         - key: karpenter.k8s.aws/instance-family
#           operator: In
#           values:
#           - t3
#           - t3a
#           - m5
#           - c5
#       limits:
#         resources:
#           cpu: 1000
#           memory: 20Gi
#       providerRef:
#         name: default
#       ttlSecondsAfterEmpty: 30
#   YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }


# resource "kubectl_manifest" "karpenter_node_template" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.k8s.aws/v1alpha1
#     kind: AWSNodeTemplate
#     metadata:
#       name: default
#     spec:
#       subnetSelector:
#         karpenter.sh/discovery: ${module.eks.cluster_name}
#       securityGroupSelector:
#         karpenter.sh/discovery: ${module.eks.cluster_name}
#       tags:
#         karpenter.sh/discovery: ${module.eks.cluster_name}
#   YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }

