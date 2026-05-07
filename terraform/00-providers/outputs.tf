output "region" {
  // v6 renamed `name` -> `region` on the aws_region data source.
  value = data.aws_region.current.region
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "env" {
  value = var.env
}

output "tags" {
  value = var.tags
}

output "domain_name" {
  value = var.domain_name
}

output "hosted_zone_id" {
  value = var.hosted_zone_id
}

output "alarm_email" {
  value = var.alarm_email
}

output "ssh_keypair_name" {
  value = var.ssh_keypair_name
}
