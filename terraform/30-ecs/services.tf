// App service - two replicas of hello-world. CPU/memory drive bin-packing
// onto the t3.micro ASG; defaults sized so two tasks fit one t3.micro
// (cpu=256, memory=512) and ECS doesn't trigger ASG scale-out.
module "app_service" {
  source = "../modules/ecs_service"

  name           = "hello"
  env            = var.env
  cluster_arn    = aws_ecs_cluster.app.arn
  desired_count  = var.app_service.desired_count
  cpu            = var.app_service.cpu
  memory         = var.app_service.memory
  image          = "${aws_ecr_repository.hello.repository_url}:${var.app_service.image_tag}"
  container_port = var.app_service.container_port
  log_group_name = aws_cloudwatch_log_group.app.name
  region         = var.region

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  vpc_id            = local.app_vpc_id
  listener_arn      = aws_lb_listener.app_https.arn
  listener_priority = var.app_service.listener_priority
  host_header       = "*.${local.domain_name}"
  // /health is the path the infrastructureascode/hello-world image actually
  // serves with 200. /healthz returns 404 from this base image.
  health_check_path = var.app_service.health_check_path

  container_health_check    = var.container_health_check
  target_group_health_check = var.target_group_health_check

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
}

// Jenkins service - single replica; image mirrored from jenkins/jenkins:lts.
// Memory is 512 not 1024 because t3.micro has only ~600 MiB usable after
// host kernel + Docker daemon + ECS agent overhead.
module "jenkins_service" {
  source = "../modules/ecs_service"

  name           = "jenkins"
  env            = var.env
  cluster_arn    = aws_ecs_cluster.jenkins.arn
  desired_count  = var.jenkins_service.desired_count
  cpu            = var.jenkins_service.cpu
  memory         = var.jenkins_service.memory
  image          = "${aws_ecr_repository.jenkins.repository_url}:${var.jenkins_service.image_tag}"
  container_port = var.jenkins_service.container_port
  log_group_name = aws_cloudwatch_log_group.jenkins.name
  region         = var.region

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  vpc_id            = local.jenkins_vpc_id
  listener_arn      = aws_lb_listener.jenkins_https.arn
  listener_priority = var.jenkins_service.listener_priority
  host_header       = "jenkins.${local.domain_name}"
  health_check_path = var.jenkins_service.health_check_path

  container_health_check    = var.container_health_check
  target_group_health_check = var.target_group_health_check

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
}
