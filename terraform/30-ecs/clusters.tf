// CloudWatch log groups - explicit so retention is enforced (default is forever).
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.env}/app"
  retention_in_days = var.log_retention_days
}

// Same for Jenkins.
resource "aws_cloudwatch_log_group" "jenkins" {
  name              = "/ecs/${var.env}/jenkins"
  retention_in_days = var.log_retention_days
}

// ECS cluster (app).
resource "aws_ecs_cluster" "app" {
  name = "app-${var.env}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

// ECS cluster (jenkins).
resource "aws_ecs_cluster" "jenkins" {
  name = "jenkins-${var.env}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

// Launch template (app): instance type, AMI, instance profile, ECS join script.
resource "aws_launch_template" "app" {
  name_prefix            = "ecs-app-${var.env}-"
  image_id               = data.aws_ami.ecs.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [local.ecs_app_sg_id]
  key_name               = local.ssh_keypair_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  // IMDSv2 mandatory - stops SSRF -> credential exfiltration.
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  user_data = base64encode(<<-EOT
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.app.name} >> /etc/ecs/ecs.config
  EOT
  )
}

// ASG (app) - 2 instances per brief, across both private subnets.
resource "aws_autoscaling_group" "app" {
  name                  = "ecs-app-${var.env}"
  min_size              = var.asg_min
  max_size              = var.asg_max
  desired_capacity      = var.asg_min
  vpc_zone_identifier   = local.app_private_subnets
  protect_from_scale_in = false

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ecs-app-${var.env}"
    propagate_at_launch = true
  }

  // AmazonECSManaged tag is required by the ECS managed scaling policy.
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

// Capacity provider (app): ECS scales the ASG by target capacity utilization.
resource "aws_ecs_capacity_provider" "app" {
  name = "cp-app-${var.env}"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.app.arn
    managed_termination_protection = "DISABLED"
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = var.capacity_provider_target_capacity
      minimum_scaling_step_size = var.capacity_provider_min_step
      maximum_scaling_step_size = var.capacity_provider_max_step
    }
  }
}

// Bind the capacity provider to the cluster as default.
resource "aws_ecs_cluster_capacity_providers" "app" {
  cluster_name       = aws_ecs_cluster.app.name
  capacity_providers = [aws_ecs_capacity_provider.app.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.app.name
    weight            = 1
    base              = 0
  }
}

// Launch template (jenkins): same wiring, jenkins cluster join.
resource "aws_launch_template" "jenkins" {
  name_prefix            = "ecs-jenkins-${var.env}-"
  image_id               = data.aws_ami.ecs.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [local.ecs_jenkins_sg_id]
  key_name               = local.ssh_keypair_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  user_data = base64encode(<<-EOT
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.jenkins.name} >> /etc/ecs/ecs.config
  EOT
  )
}

// ASG (jenkins).
resource "aws_autoscaling_group" "jenkins" {
  name                  = "ecs-jenkins-${var.env}"
  min_size              = var.asg_min
  max_size              = var.asg_max
  desired_capacity      = var.asg_min
  vpc_zone_identifier   = local.jenkins_private_subnets
  protect_from_scale_in = false

  launch_template {
    id      = aws_launch_template.jenkins.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ecs-jenkins-${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

// Capacity provider (jenkins).
resource "aws_ecs_capacity_provider" "jenkins" {
  name = "cp-jenkins-${var.env}"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.jenkins.arn
    managed_termination_protection = "DISABLED"
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = var.capacity_provider_target_capacity
      minimum_scaling_step_size = var.capacity_provider_min_step
      maximum_scaling_step_size = var.capacity_provider_max_step
    }
  }
}

// Bind capacity provider to jenkins cluster.
resource "aws_ecs_cluster_capacity_providers" "jenkins" {
  cluster_name       = aws_ecs_cluster.jenkins.name
  capacity_providers = [aws_ecs_capacity_provider.jenkins.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.jenkins.name
    weight            = 1
    base              = 0
  }
}
