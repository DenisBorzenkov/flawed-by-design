output "tfstate_bucket" {
  value       = aws_s3_bucket.tfstate.id
  description = "Name of the state bucket - feed into per-account backend.tfbackend."
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

// Ready-to-paste backend.tfbackend content for downstream layers.
output "backend_hcl" {
  value = <<-EOT
    bucket       = "${aws_s3_bucket.tfstate.id}"
    region       = "${var.region}"
    use_lockfile = true
    encrypt      = true
  EOT
}
