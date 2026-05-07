// Target group: the ALB will route to the bridge-mode container's host port
// (resolved at task placement time). Container ports go in the task def.
resource "aws_lb_target_group" "this" {
  name        = "tg-${var.name}-${var.env}"
  vpc_id      = var.vpc_id
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "instance"

  health_check {
    path                = var.health_check_path
    matcher             = var.target_group_health_check.matcher
    interval            = var.target_group_health_check.interval_seconds
    timeout             = var.target_group_health_check.timeout_seconds
    healthy_threshold   = var.target_group_health_check.healthy_threshold
    unhealthy_threshold = var.target_group_health_check.unhealthy_threshold
  }
  deregistration_delay = var.target_group_health_check.deregistration_delay
}

// Listener rule binds {host_header} -> this target group.
resource "aws_lb_listener_rule" "this" {
  listener_arn = var.listener_arn
  priority     = var.listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
  condition {
    host_header {
      values = [var.host_header]
    }
  }
}

// Task definition. bridge networking lets the ALB pick a dynamic host port
// per task - required for >1 replica per instance on small EC2 types.
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name}-${var.env}"
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = var.network_mode
  requires_compatibilities = ["EC2"]
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = var.name
        }
      }
      // Container-level (Docker) health check. Defaults are tunable via
      // var.container_health_check; values set in 30-ecs/variables.tf are
      // production-safe (interval >= 30s, startPeriod >= 30s).
      healthCheck = {
        command     = ["CMD-SHELL", "/usr/local/bin/verify_health http://localhost:${var.container_port}${var.health_check_path} || exit 1"]
        interval    = var.container_health_check.interval_seconds
        retries     = var.container_health_check.retries
        startPeriod = var.container_health_check.start_period_seconds
        timeout     = var.container_health_check.timeout_seconds
      }
    }
  ])
}

// Service binds task def + target group + cluster. force_new_deployment lets
// CI roll a new image tag without recreating the resource.
resource "aws_ecs_service" "this" {
  name            = "${var.name}-${var.env}"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.name
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  ordered_placement_strategy {
    type  = var.placement_strategy_type
    field = var.placement_strategy_field
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
