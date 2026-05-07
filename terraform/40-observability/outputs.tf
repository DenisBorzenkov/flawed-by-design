output "ops_topic_arn" {
  value = aws_sns_topic.ops.arn
}

output "us_east_1_ops_topic_arn" {
  value = aws_sns_topic.us_east_1_ops.arn
}

output "app_health_check_id" {
  value = aws_route53_health_check.app.id
}

output "jenkins_health_check_id" {
  value = aws_route53_health_check.jenkins.id
}
