// Conditional R53 records - only created when a hosted_zone_id was provided.
resource "aws_route53_record" "app" {
  count   = local.hosted_zone_id == null ? 0 : 1
  zone_id = local.hosted_zone_id
  name    = "app.${local.domain_name}"
  type    = "A"
  alias {
    name                   = local.app_alb_dns
    zone_id                = local.app_alb_zone
    evaluate_target_health = true
  }
}

// Conditional R53 record for Jenkins.
resource "aws_route53_record" "jenkins" {
  count   = local.hosted_zone_id == null ? 0 : 1
  zone_id = local.hosted_zone_id
  name    = "jenkins.${local.domain_name}"
  type    = "A"
  alias {
    name                   = local.jenkins_alb_dns
    zone_id                = local.jenkins_alb_zone
    evaluate_target_health = true
  }
}
