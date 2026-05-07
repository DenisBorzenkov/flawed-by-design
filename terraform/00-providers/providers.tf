// Primary regional provider - every layer pins eu-central-1 here.
provider "aws" {
  region = var.region
  default_tags {
    tags = var.tags
  }
}

// us_east_1 alias is declared inside 40-observability - that is where the
// us-east-1-only metrics (AWS/Billing.EstimatedCharges and
// AWS/Route53.HealthCheckStatus) are consumed. Provider configurations do
// not propagate across remote-state-linked roots, so declaring it here is
// dead code (tflint terraform_unused_declarations).
