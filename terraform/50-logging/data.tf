data "terraform_remote_state" "providers" {
  backend = "s3"
  config = {
    bucket = var.tfstate_bucket
    key    = "00-providers.tfstate"
    region = var.region
  }
}

locals {
  account_id = data.terraform_remote_state.providers.outputs.account_id
}
