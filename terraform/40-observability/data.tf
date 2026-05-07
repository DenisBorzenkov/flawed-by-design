data "terraform_remote_state" "providers" {
  backend = "s3"
  config = {
    bucket = var.tfstate_bucket
    key    = "00-providers.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "ecs" {
  backend = "s3"
  config = {
    bucket = var.tfstate_bucket
    key    = "30-ecs.tfstate"
    region = var.region
  }
}

locals {
  alarm_email = data.terraform_remote_state.providers.outputs.alarm_email
  domain_name = data.terraform_remote_state.providers.outputs.domain_name
  // try() because terraform_remote_state strips null-valued outputs entirely.
  hosted_zone_id = try(data.terraform_remote_state.providers.outputs.hosted_zone_id, null)

  app_alb_dns      = data.terraform_remote_state.ecs.outputs.app_alb_dns
  app_alb_zone     = data.terraform_remote_state.ecs.outputs.app_alb_zone_id
  app_alb_arn      = data.terraform_remote_state.ecs.outputs.app_alb_arn
  app_tg_arn       = data.terraform_remote_state.ecs.outputs.app_target_group_arn
  jenkins_alb_dns  = data.terraform_remote_state.ecs.outputs.jenkins_alb_dns
  jenkins_alb_zone = data.terraform_remote_state.ecs.outputs.jenkins_alb_zone_id
  jenkins_alb_arn  = data.terraform_remote_state.ecs.outputs.jenkins_alb_arn
  jenkins_tg_arn   = data.terraform_remote_state.ecs.outputs.jenkins_target_group_arn

  // CloudWatch ALB dimension uses the ARN suffix only (e.g. app/<name>/<id>).
  // Same for target groups (targetgroup/<name>/<id>).
  app_alb_suffix     = regex("app/.*", local.app_alb_arn)
  jenkins_alb_suffix = regex("app/.*", local.jenkins_alb_arn)
  app_tg_suffix      = regex("targetgroup/.*", local.app_tg_arn)
  jenkins_tg_suffix  = regex("targetgroup/.*", local.jenkins_tg_arn)
}
