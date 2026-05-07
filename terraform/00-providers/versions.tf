terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.44"
    }
  }
  // Partial config - bucket/region/use_lockfile/encrypt come from
  // `accounts/<acct>/backend.tfbackend`; key is supplied inline at init time.
  backend "s3" {}
}
