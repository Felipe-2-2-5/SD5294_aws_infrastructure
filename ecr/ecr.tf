data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  common_repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Expire images older than 14 days",
        selection = {
          tagStatus   = "untagged",
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 14
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  repository_image_tag_mutability = "MUTABLE"
  common_repository_policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Sid    = "AllowPushPull",
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::${local.account_id}:root",
            "arn:aws:iam::${local.account_id}:user/eks_user"
          ]
        },
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:DescribeImageScanFindings",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:ListTagsForResource"
        ]
      }
    ]
  })

  common_repo_list = [
    "${var.project}-${var.environment}-backend",
    "${var.project}-${var.environment}-frontend",
    "${var.project}-${var.environment}-app1",
    "${var.project}-${var.environment}-app2"
  ]
}


module "ecr" {
  source                            = "terraform-aws-modules/ecr/aws"
  version                           = "~> 1.5.1"
  for_each                          = toset(local.common_repo_list)
  repository_name                   = each.value
  repository_read_write_access_arns = ["arn:aws:iam::${local.account_id}:user/eks_user"]
  repository_lifecycle_policy       = local.common_repository_lifecycle_policy
  repository_policy                 = local.common_repository_policy
  create_repository_policy          = false
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
