// eu-central-1 ops topic - every regional alarm funnels here so subscribers
// see one stream.
resource "aws_sns_topic" "ops" {
  name = "ops-${var.env}"
}

// Email subscription. Confirmation is OUT-OF-BAND: AWS sends a confirm link
// to the subscriber and PendingConfirmation persists in TF state until
// clicked. See README "Manual SNS-confirm step".
resource "aws_sns_topic_subscription" "ops_email" {
  topic_arn = aws_sns_topic.ops.arn
  protocol  = "email"
  endpoint  = local.alarm_email
}

// us-east-1 ops topic - required because two metric namespaces only publish
// to us-east-1 and CloudWatch alarms must take actions in their own region:
//   - AWS/Billing.EstimatedCharges (the cost alarm)
//   - AWS/Route53.HealthCheckStatus (the per-ALB health-check alarms)
resource "aws_sns_topic" "us_east_1_ops" {
  provider = aws.us_east_1
  name     = "ops-${var.env}-us-east-1"
}

// Email subscription for the us-east-1 topic (same out-of-band confirm flow).
resource "aws_sns_topic_subscription" "us_east_1_ops_email" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.us_east_1_ops.arn
  protocol  = "email"
  endpoint  = local.alarm_email
}
