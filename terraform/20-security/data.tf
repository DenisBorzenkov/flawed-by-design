data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.tfstate_bucket
    key    = "10-network.tfstate"
    region = var.region
  }
}

locals {
  app_vpc_id              = data.terraform_remote_state.network.outputs.app_vpc_id
  app_vpc_cidr            = data.terraform_remote_state.network.outputs.app_vpc_cidr
  app_public_subnets      = data.terraform_remote_state.network.outputs.app_public_subnets
  app_private_subnets     = data.terraform_remote_state.network.outputs.app_private_subnets
  jenkins_vpc_id          = data.terraform_remote_state.network.outputs.jenkins_vpc_id
  jenkins_vpc_cidr        = data.terraform_remote_state.network.outputs.jenkins_vpc_cidr
  jenkins_public_subnets  = data.terraform_remote_state.network.outputs.jenkins_public_subnets
  jenkins_private_subnets = data.terraform_remote_state.network.outputs.jenkins_private_subnets
}
