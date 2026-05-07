// Cost alarm - brief: "costs > $1/day".
// AWS/Billing.EstimatedCharges is a *cumulative* monthly counter, not a
// daily delta - there is no native per-day metric. With threshold=$1, the
// alarm trips on the first day spend exceeds $1, which functionally matches
// the brief's intent on day 1 of a billing cycle. AWS Budgets is the
// canonical way to do true per-day; brief stipulated CloudWatch.
// Lives in us-east-1 because that's the only region the metric publishes to.
resource "aws_cloudwatch_metric_alarm" "billing" {
  provider            = aws.us_east_1
  alarm_name          = "billing-${var.env}-over-${var.billing_threshold_usd}usd"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = var.billing_alarm_period_seconds // default 6h - billing metrics update infrequently
  statistic           = "Maximum"
  threshold           = var.billing_threshold_usd
  treat_missing_data  = "notBreaching"
  dimensions = {
    Currency = "USD"
  }
  alarm_actions = [aws_sns_topic.us_east_1_ops.arn]
}
