// App-tier VPC. No NAT - egress to AWS APIs is via VPC endpoints only.
module "vpc_app" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "app-${var.env}"
  cidr = var.app_vpc_cidr
  azs  = local.azs

  public_subnets  = var.app_public_subnet_cidrs
  private_subnets = var.app_private_subnet_cidrs

  enable_nat_gateway   = false
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  // Per-subnet tag lets ALBs/Service Discovery target by role.
  public_subnet_tags  = { Tier = "public", Role = "alb" }
  private_subnet_tags = { Tier = "private", Role = "ecs" }
}

// Jenkins-tier VPC. Same shape; isolated for blast-radius and IP planning.
module "vpc_jenkins" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "jenkins-${var.env}"
  cidr = var.jenkins_vpc_cidr
  azs  = local.azs

  public_subnets  = var.jenkins_public_subnet_cidrs
  private_subnets = var.jenkins_private_subnet_cidrs

  enable_nat_gateway   = false
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags  = { Tier = "public", Role = "alb" }
  private_subnet_tags = { Tier = "private", Role = "ecs" }
}
