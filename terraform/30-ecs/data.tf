data "terraform_remote_state" "providers" {
  backend = "s3"
  config = {
    bucket = var.tfstate_bucket
    key    = "00-providers.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.tfstate_bucket
    key    = "10-network.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"
  config = {
    bucket = var.tfstate_bucket
    key    = "20-security.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "logging" {
  backend = "s3"
  config = {
    bucket = var.tfstate_bucket
    key    = "50-logging.tfstate"
    region = var.region
  }
}

// ECS-optimized AL2023 AMI for the ASG launch template.
data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = [var.ecs_ami_name_pattern]
  }
}

locals {
  account_id = data.terraform_remote_state.providers.outputs.account_id
  // try() because terraform_remote_state strips null-valued outputs entirely.
  ssh_keypair_name        = try(data.terraform_remote_state.providers.outputs.ssh_keypair_name, null)
  domain_name             = data.terraform_remote_state.providers.outputs.domain_name
  app_vpc_id              = data.terraform_remote_state.network.outputs.app_vpc_id
  app_private_subnets     = data.terraform_remote_state.network.outputs.app_private_subnets
  app_public_subnets      = data.terraform_remote_state.network.outputs.app_public_subnets
  jenkins_vpc_id          = data.terraform_remote_state.network.outputs.jenkins_vpc_id
  jenkins_private_subnets = data.terraform_remote_state.network.outputs.jenkins_private_subnets
  jenkins_public_subnets  = data.terraform_remote_state.network.outputs.jenkins_public_subnets
  alb_app_sg_id           = data.terraform_remote_state.security.outputs.alb_app_sg_id
  ecs_app_sg_id           = data.terraform_remote_state.security.outputs.ecs_app_sg_id
  alb_jenkins_sg_id       = data.terraform_remote_state.security.outputs.alb_jenkins_sg_id
  ecs_jenkins_sg_id       = data.terraform_remote_state.security.outputs.ecs_jenkins_sg_id
  jenkins_waf_arn         = data.terraform_remote_state.security.outputs.jenkins_waf_arn
  log_bucket_id           = data.terraform_remote_state.logging.outputs.log_bucket_id
}
