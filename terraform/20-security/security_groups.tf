// ALB SG (app): open 443 from Internet - public-facing ALB.
resource "aws_security_group" "alb_app" {
  name        = "alb-app-${var.env}"
  description = "App ALB ingress 443"
  vpc_id      = local.app_vpc_id

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "to ECS tasks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.app_vpc_cidr]
  }
}

// ECS SG (app): only ALB SG can talk to tasks; no direct Internet.
resource "aws_security_group" "ecs_app" {
  name        = "ecs-app-${var.env}"
  description = "App ECS task SG - ALB-only ingress"
  vpc_id      = local.app_vpc_id

  ingress {
    description     = "from app ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_app.id]
  }
  egress {
    description = "general egress (constrained by VPC endpoints + no NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// ALB SG (jenkins): 443 from Internet - geo enforcement happens in WAF, not here.
// SGs cannot match by country because they are stateless-set L4 filters keyed on
// CIDR/SG/prefix-list IDs only - there is no IP-to-geo metadata in the SG
// evaluator. WAFv2's geo_match_statement dereferences the AWS GeoIP DB at
// request time, which is why filtering by PT must live at L7 (WAF) and not at
// L4 (SG).
resource "aws_security_group" "alb_jenkins" {
  name        = "alb-jenkins-${var.env}"
  description = "Jenkins ALB ingress 443 (geo at WAF, not SG)"
  vpc_id      = local.jenkins_vpc_id

  ingress {
    description = "HTTPS from anywhere (geo-filtered downstream by WAF)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "to ECS tasks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.jenkins_vpc_cidr]
  }
}

// ECS SG (jenkins): ALB ingress only.
resource "aws_security_group" "ecs_jenkins" {
  name        = "ecs-jenkins-${var.env}"
  description = "Jenkins ECS task SG - ALB-only ingress"
  vpc_id      = local.jenkins_vpc_id

  ingress {
    description     = "from jenkins ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_jenkins.id]
  }
  egress {
    description = "general egress (constrained by VPC endpoints + no NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
