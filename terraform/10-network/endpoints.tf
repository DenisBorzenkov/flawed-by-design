// Endpoint-shared SG: only allow 443 from inside the owning VPC.
resource "aws_security_group" "endpoints_app" {
  name        = "endpoints-app-${var.env}"
  description = "VPC endpoint ENI SG (app)"
  vpc_id      = module.vpc_app.vpc_id

  ingress {
    description = "443 from app VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc_app.vpc_cidr_block]
  }
  egress {
    description = "endpoint ENI return traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Same SG model for Jenkins VPC.
resource "aws_security_group" "endpoints_jenkins" {
  name        = "endpoints-jenkins-${var.env}"
  description = "VPC endpoint ENI SG (jenkins)"
  vpc_id      = module.vpc_jenkins.vpc_id

  ingress {
    description = "443 from jenkins VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc_jenkins.vpc_cidr_block]
  }
  egress {
    description = "endpoint ENI return traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Interface endpoints. Brief listed ECR/S3/Logs/SSM, but ECS-on-EC2 with
// no NAT also needs ecs/ecs-agent/ecs-telemetry - without these, the ECS
// agent on the host cannot register with the cluster control plane and
// tasks pend forever ("No Container Instances were found"). The default
// list in var.interface_endpoints reflects that minimum set.

// App VPC interface endpoints - private DNS so SDKs resolve transparently.
resource "aws_vpc_endpoint" "app_interface" {
  for_each            = toset(var.interface_endpoints)
  vpc_id              = module.vpc_app.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc_app.private_subnets
  security_group_ids  = [aws_security_group.endpoints_app.id]
  private_dns_enabled = true
}

// App S3 gateway endpoint - required so ECR layer pulls don't egress via NAT.
resource "aws_vpc_endpoint" "app_s3" {
  vpc_id            = module.vpc_app.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc_app.private_route_table_ids
}

// Jenkins VPC interface endpoints - same set as app.
resource "aws_vpc_endpoint" "jenkins_interface" {
  for_each            = toset(var.interface_endpoints)
  vpc_id              = module.vpc_jenkins.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc_jenkins.private_subnets
  security_group_ids  = [aws_security_group.endpoints_jenkins.id]
  private_dns_enabled = true
}

// Jenkins S3 gateway endpoint - also used for build-log uploads from agents.
resource "aws_vpc_endpoint" "jenkins_s3" {
  vpc_id            = module.vpc_jenkins.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc_jenkins.private_route_table_ids
}
