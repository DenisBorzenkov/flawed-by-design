output "alb_app_sg_id" {
  value = aws_security_group.alb_app.id
}

output "ecs_app_sg_id" {
  value = aws_security_group.ecs_app.id
}

output "alb_jenkins_sg_id" {
  value = aws_security_group.alb_jenkins.id
}

output "ecs_jenkins_sg_id" {
  value = aws_security_group.ecs_jenkins.id
}

output "jenkins_waf_arn" {
  value = aws_wafv2_web_acl.jenkins.arn
}
