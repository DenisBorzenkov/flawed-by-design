// Throwaway TLS keypair - replace with an ACM-issued cert in production. The
// brief allows for a manual cert wire-up; this lets `terraform apply` produce
// a working 443 listener without DNS pre-reqs.
resource "tls_private_key" "self" {
  algorithm = "RSA"
  rsa_bits  = var.tls_rsa_bits
}

// Self-signed cert good for 1y. CN/SAN match the public ALB DNS names later.
resource "tls_self_signed_cert" "self" {
  private_key_pem = tls_private_key.self.private_key_pem
  subject {
    common_name = "*.${local.domain_name}"
  }
  validity_period_hours = var.tls_validity_hours
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
  dns_names = [
    "*.${local.domain_name}",
    local.domain_name,
  ]
}

// Import into ACM - ALB only accepts ACM-managed certs.
resource "aws_acm_certificate" "self" {
  private_key      = tls_private_key.self.private_key_pem
  certificate_body = tls_self_signed_cert.self.cert_pem
}
