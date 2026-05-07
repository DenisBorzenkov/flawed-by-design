// App ALB target health < 1 -> ops topic.
resource "aws_cloudwatch_metric_alarm" "app_health" {
  alarm_name          = "app-${var.env}-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alb_health_alarm.evaluation_periods
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = var.alb_health_alarm.period_seconds
  statistic           = "Minimum"
  threshold           = var.alb_health_alarm.threshold
  treat_missing_data  = "breaching"
  dimensions = {
    LoadBalancer = local.app_alb_suffix
    TargetGroup  = local.app_tg_suffix
  }
  alarm_actions = [aws_sns_topic.ops.arn]
  ok_actions    = [aws_sns_topic.ops.arn]
}

// App ALB 5xx > 0 -> ops (brief: HTTP 5xx errors > 0).
resource "aws_cloudwatch_metric_alarm" "app_5xx" {
  alarm_name          = "app-${var.env}-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alb_5xx_alarm.evaluation_periods
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.alb_5xx_alarm.period_seconds
  statistic           = "Sum"
  threshold           = var.alb_5xx_alarm.threshold
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = local.app_alb_suffix
  }
  alarm_actions = [aws_sns_topic.ops.arn]
}

// Jenkins ALB target health < 1 -> ops topic.
resource "aws_cloudwatch_metric_alarm" "jenkins_health" {
  alarm_name          = "jenkins-${var.env}-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alb_health_alarm.evaluation_periods
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = var.alb_health_alarm.period_seconds
  statistic           = "Minimum"
  threshold           = var.alb_health_alarm.threshold
  treat_missing_data  = "breaching"
  dimensions = {
    LoadBalancer = local.jenkins_alb_suffix
    TargetGroup  = local.jenkins_tg_suffix
  }
  alarm_actions = [aws_sns_topic.ops.arn]
  ok_actions    = [aws_sns_topic.ops.arn]
}

// Jenkins ALB 5xx > 0 -> ops.
resource "aws_cloudwatch_metric_alarm" "jenkins_5xx" {
  alarm_name          = "jenkins-${var.env}-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alb_5xx_alarm.evaluation_periods
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.alb_5xx_alarm.period_seconds
  statistic           = "Sum"
  threshold           = var.alb_5xx_alarm.threshold
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = local.jenkins_alb_suffix
  }
  alarm_actions = [aws_sns_topic.ops.arn]
}
