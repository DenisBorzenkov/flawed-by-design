output "target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "service_name" {
  value = aws_ecs_service.this.name
}

output "task_family" {
  value = aws_ecs_task_definition.this.family
}
