module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "${var.project}-${var.environment}-vpc"
  cidr   = var.cidr_vpc

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.cidr_vpc, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.cidr_vpc, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(var.cidr_vpc, 8, k + 52)]

  enable_nat_gateway = true
  single_nat_gateway = var.environment == "dev" ? true : false
  # enable_vpn_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true


  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1

  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = module.env.eks_name
  }


  tags = merge(module.env.common_tags, {
    Terraform = "true"
  })
}


################################################################################
# Supporting Resources
################################################################################
resource "aws_security_group" "vpc_tls" {
  name_prefix = "vpc_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = module.env.tags
}
