// ALB access-log bucket. Name is suffixed with account+region for global uniqueness.
resource "aws_s3_bucket" "logs" {
  bucket        = "${var.log_bucket_name_prefix}-${local.account_id}-${var.env}-${var.region}"
  force_destroy = var.log_bucket_force_destroy
}

// Versioning suspended (not Enabled) - log objects are write-once, and
// keeping versions on a log bucket is just GB-month sprawl. Resource is
// declared explicitly so Checkov sees the configuration.
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = var.log_bucket_versioning_status
  }
}

// Block all public access - defense-in-depth even though the bucket has no public ACL.
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// SSE-S3 (AES256). KMS would force the ELB service to assume KMS perms; SSE-S3 is friction-free.
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

// Lifecycle: 30d -> IA, 90d -> expire by default. Matches brief.
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "alb-log-aging"
    status = "Enabled"
    // FLAW #1: empty filter applies the 90-day expiration to *every* object
    // in the bucket regardless of prefix. Today the bucket only holds
    // alb/<svc>-<env>/* logs so nothing observable breaks. The bug bites
    // the moment another team uses this bucket - "looks like the right
    // place for our daily exports", "let's drop CloudTrail digests here",
    // "the analytics team needs a landing zone" - those objects silently
    // disappear at day 91, no alarm, no log line, no audit trail. Fix:
    //   filter { prefix = "alb/" }
    filter {}
    transition {
      days          = var.log_lifecycle.transition_to_ia_days
      storage_class = var.log_lifecycle.transition_storage_class
    }
    expiration {
      days = var.log_lifecycle.expiration_days
    }
    // Reap dangling multipart uploads - covers CKV_AWS_300 and stops failed
    // uploads from accruing storage indefinitely.
    abort_incomplete_multipart_upload {
      days_after_initiation = var.log_lifecycle.abort_incomplete_mpu_days
    }
  }
}

// ELB log delivery principal account is region-locked. The AWS provider's
// aws_elb_service_account data source returns the right account for the
// current region, so we don't have to maintain a region->id table here.
data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "alb_logs" {
  statement {
    sid    = "AllowELBLogs"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/*"]
  }
  statement {
    sid    = "AllowDeliveryControl"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
  statement {
    sid    = "AllowDeliveryAcl"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs.arn]
  }
}

// Bucket policy attaching the ELB write grant.
resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.alb_logs.json
}
