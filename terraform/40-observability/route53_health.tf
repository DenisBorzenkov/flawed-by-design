// Route53 health checks for each ALB.
// Brief: "Route53 health checks for each ALB". Probes run from AWS edge
// locations against the ALB DNS, which gives a true external-reachability
// signal (vs. AWS/ApplicationELB metrics which are internal).
// Health checks are a global Route53 service; the resource has no region.
resource "aws_route53_health_check" "app" {
  fqdn              = local.app_alb_dns
  port              = var.route53_health_check.port
  type              = var.route53_health_check.type
  resource_path     = var.route53_health_check.app_path
  failure_threshold = var.route53_health_check.failure_threshold
  request_interval  = var.route53_health_check.request_interval
  measure_latency   = var.route53_health_check.measure_latency
  tags = {
    Name = "app-${var.env}"
  }
}

// Same probe for the Jenkins ALB. /login is the Jenkins liveness URL.
resource "aws_route53_health_check" "jenkins" {
  fqdn              = local.jenkins_alb_dns
  port              = var.route53_health_check.port
  type              = var.route53_health_check.type
  resource_path     = var.route53_health_check.jenkins_path
  failure_threshold = var.route53_health_check.failure_threshold
  request_interval  = var.route53_health_check.request_interval
  measure_latency   = var.route53_health_check.measure_latency
  tags = {
    Name = "jenkins-${var.env}"
  }
}

// HealthCheckStatus < 1 means UNHEALTHY. The metric is published in
// us-east-1 only, so the alarm and its SNS action both live there.
resource "aws_cloudwatch_metric_alarm" "app_r53_health" {
  provider            = aws.us_east_1
  alarm_name          = "app-${var.env}-r53-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.route53_health_alarm.evaluation_periods
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = var.route53_health_alarm.period_seconds
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "breaching"
  dimensions = {
    HealthCheckId = aws_route53_health_check.app.id
  }
  alarm_actions = [aws_sns_topic.us_east_1_ops.arn]
  ok_actions    = [aws_sns_topic.us_east_1_ops.arn]
}

// Same alarm for the Jenkins health check.
resource "aws_cloudwatch_metric_alarm" "jenkins_r53_health" {
  provider            = aws.us_east_1
  alarm_name          = "jenkins-${var.env}-r53-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.route53_health_alarm.evaluation_periods
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = var.route53_health_alarm.period_seconds
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "breaching"
  dimensions = {
    HealthCheckId = aws_route53_health_check.jenkins.id
  }
  alarm_actions = [aws_sns_topic.us_east_1_ops.arn]
  ok_actions    = [aws_sns_topic.us_east_1_ops.arn]
}
