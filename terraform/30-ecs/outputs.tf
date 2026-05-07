output "app_alb_arn" {
  value = aws_lb.app.arn
}

output "app_alb_dns" {
  value = aws_lb.app.dns_name
}

output "app_alb_zone_id" {
  value = aws_lb.app.zone_id
}

output "app_alb_https_listener_arn" {
  value = aws_lb_listener.app_https.arn
}

output "app_cluster_arn" {
  value = aws_ecs_cluster.app.arn
}

output "app_cluster_name" {
  value = aws_ecs_cluster.app.name
}

output "app_log_group_name" {
  value = aws_cloudwatch_log_group.app.name
}

output "jenkins_alb_arn" {
  value = aws_lb.jenkins.arn
}

output "jenkins_alb_dns" {
  value = aws_lb.jenkins.dns_name
}

output "jenkins_alb_zone_id" {
  value = aws_lb.jenkins.zone_id
}

output "jenkins_alb_https_listener_arn" {
  value = aws_lb_listener.jenkins_https.arn
}

output "jenkins_cluster_arn" {
  value = aws_ecs_cluster.jenkins.arn
}

output "jenkins_cluster_name" {
  value = aws_ecs_cluster.jenkins.name
}

output "jenkins_log_group_name" {
  value = aws_cloudwatch_log_group.jenkins.name
}

output "ecs_execution_role_arn" {
  value = aws_iam_role.execution.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.task.arn
}

output "app_target_group_arn" {
  value = module.app_service.target_group_arn
}

output "jenkins_target_group_arn" {
  value = module.jenkins_service.target_group_arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.hello.repository_url
}

output "jenkins_ecr_repository_url" {
  value = aws_ecr_repository.jenkins.repository_url
}
