// Primary regional provider.
provider "aws" {
  region = var.region
  default_tags {
    tags = var.tags
  }
}

// us-east-1 alias is mandatory for AWS/Billing CloudWatch metrics.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = var.tags
  }
}
