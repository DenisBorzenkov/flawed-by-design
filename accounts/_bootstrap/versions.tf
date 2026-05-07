terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.44"
    }
  }
  // Bootstrap intentionally uses LOCAL backend - it creates the S3 bucket
  // and DynamoDB table that all other layers will use as their backend.
  // Chicken-and-egg: state-of-state-backend has to live somewhere else.
  backend "local" {}
}
