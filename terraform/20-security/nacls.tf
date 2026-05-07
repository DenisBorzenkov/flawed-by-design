// NACL design:
//   - Brief: "Network ACLs: Block non-HTTPS inbound traffic, aligning with SGs."
//   - NACLs are STATELESS, so we must explicitly allow the ephemeral return
//     range (1024-65535) for any reply traffic. Without it, a 443 client ->
//     ALB request opens a server socket but the client return uses an
//     ephemeral source port (RFC 6056 / Linux 32768-60999 / Windows
//     49152-65535) and the NACL drops the reply.
//   - Public NACLs are owned here (not in the VPC module) so the security
//     layer can evolve rules without re-applying network state.
//   - Default rule 32767 is `deny all` - anything not explicitly allowed
//     is dropped, which is what enforces "block non-HTTPS".

// App public NACL - internet-facing ALB subnets.
resource "aws_network_acl" "app_public" {
  vpc_id     = local.app_vpc_id
  subnet_ids = local.app_public_subnets

  // Inbound 443 from anywhere - only HTTPS reaches the ALB ENI.
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }
  // Inbound ephemeral return path - required because NACLs are stateless.
  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }
  // Outbound: allow all (SG remains the tighter control here).
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "app-public-${var.env}"
  }
}

// App private NACL - ECS task + VPC endpoint subnets.
// Inbound: allow own VPC + peer VPC (peering) + ephemeral return for
// outbound-initiated flows that need replies.
resource "aws_network_acl" "app_private" {
  vpc_id     = local.app_vpc_id
  subnet_ids = local.app_private_subnets

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = local.app_vpc_cidr
  }
  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = local.jenkins_vpc_cidr
  }
  ingress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "app-private-${var.env}"
  }
}

// Jenkins public NACL - same shape as app, separate VPC.
resource "aws_network_acl" "jenkins_public" {
  vpc_id     = local.jenkins_vpc_id
  subnet_ids = local.jenkins_public_subnets

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }
  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "jenkins-public-${var.env}"
  }
}

// Jenkins private NACL - Jenkins task + endpoint subnets.
resource "aws_network_acl" "jenkins_private" {
  vpc_id     = local.jenkins_vpc_id
  subnet_ids = local.jenkins_private_subnets

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = local.jenkins_vpc_cidr
  }
  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = local.app_vpc_cidr
  }
  ingress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "jenkins-private-${var.env}"
  }
}
