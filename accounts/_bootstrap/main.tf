// Discover the account ID so the bucket name is deterministic per-account.
data "aws_caller_identity" "current" {}

locals {
  // Bucket per account+region; same template every account follows.
  bucket_name = "tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"
}

// State bucket. prevent_destroy stops `terraform destroy` from dropping
// state-of-state - that would orphan every other layer's state.
resource "aws_s3_bucket" "tfstate" {
  bucket = local.bucket_name
  lifecycle {
    prevent_destroy = true
  }
}

// Versioning ON for state - every apply produces a new object version that
// can be rolled back on bad merges.
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

// SSE-S3 (AES256) - state contains secrets (provider tokens, etc).
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

// Belt-and-braces: BPA on the state bucket.
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// State locking lives in the same bucket as state objects via TF 1.10's
// native S3 lockfile mechanism (`use_lockfile = true` in each layer's
// backend config). DynamoDB is no longer required and the legacy
// `dynamodb_table` argument is on the deprecation path.
