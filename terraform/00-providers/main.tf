// Discover the executing account/region for downstream policies.
data "aws_caller_identity" "current" {}

// Discover the executing region; cheaper than rebuilding from var.region.
data "aws_region" "current" {}
