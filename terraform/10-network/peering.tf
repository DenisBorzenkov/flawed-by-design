// Bidirectional VPC peering - auto-accepted because both VPCs share an account.
resource "aws_vpc_peering_connection" "app_jenkins" {
  vpc_id      = module.vpc_app.vpc_id
  peer_vpc_id = module.vpc_jenkins.vpc_id
  auto_accept = true
  tags = {
    Name = "app-jenkins-${var.env}"
  }
}

// App private route tables -> Jenkins CIDR via peering.
resource "aws_route" "app_to_jenkins" {
  count                     = length(module.vpc_app.private_route_table_ids)
  route_table_id            = module.vpc_app.private_route_table_ids[count.index]
  destination_cidr_block    = module.vpc_jenkins.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.app_jenkins.id
}

// Jenkins private route tables -> App CIDR via peering.
resource "aws_route" "jenkins_to_app" {
  count                     = length(module.vpc_jenkins.private_route_table_ids)
  route_table_id            = module.vpc_jenkins.private_route_table_ids[count.index]
  destination_cidr_block    = module.vpc_app.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.app_jenkins.id
}
