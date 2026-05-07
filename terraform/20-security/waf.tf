// WAFv2 web ACL - REGIONAL scope is required for ALB association
// (CLOUDFRONT scope only attaches to CF distributions).
resource "aws_wafv2_web_acl" "jenkins" {
  name  = "jenkins-${var.env}"
  scope = "REGIONAL"

  // Implicit deny: only PT requests are allowed through.
  default_action {
    block {}
  }

  rule {
    name     = "allow-pt-only"
    priority = 1
    action {
      allow {}
    }
    statement {
      geo_match_statement {
        country_codes = var.allowed_country_codes
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-pt"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "jenkins-acl"
    sampled_requests_enabled   = true
  }
}
