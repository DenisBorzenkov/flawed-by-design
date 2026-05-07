// App ALB: public, internet-facing. Access logs land in the 50-logging bucket.
resource "aws_lb" "app" {
  name                       = "app-${var.env}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [local.alb_app_sg_id]
  subnets                    = local.app_public_subnets
  drop_invalid_header_fields = true

  access_logs {
    bucket  = local.log_bucket_id
    prefix  = "alb/app-${var.env}"
    enabled = true
  }
}

// 443 listener with the imported self-signed cert; redirect from 80 is intentionally absent (443 only).
resource "aws_lb_listener" "app_https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.self.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "no route"
      status_code  = "404"
    }
  }
}

// Jenkins ALB: same shape, separate VPC.
resource "aws_lb" "jenkins" {
  name                       = "jenkins-${var.env}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [local.alb_jenkins_sg_id]
  subnets                    = local.jenkins_public_subnets
  drop_invalid_header_fields = true

  access_logs {
    bucket  = local.log_bucket_id
    prefix  = "alb/jenkins-${var.env}"
    enabled = true
  }
}

// Jenkins 443 listener - same self-signed cert; the WAF below filters by geo.
resource "aws_lb_listener" "jenkins_https" {
  load_balancer_arn = aws_lb.jenkins.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.self.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "no route"
      status_code  = "404"
    }
  }
}

// WAF binds to the Jenkins ALB only (App ALB has no geo restriction).
resource "aws_wafv2_web_acl_association" "jenkins" {
  resource_arn = aws_lb.jenkins.arn
  web_acl_arn  = local.jenkins_waf_arn
}
