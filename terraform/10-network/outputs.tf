output "app_vpc_id" {
  value = module.vpc_app.vpc_id
}

output "app_vpc_cidr" {
  value = module.vpc_app.vpc_cidr_block
}

output "app_public_subnets" {
  value = module.vpc_app.public_subnets
}

output "app_private_subnets" {
  value = module.vpc_app.private_subnets
}

output "jenkins_vpc_id" {
  value = module.vpc_jenkins.vpc_id
}

output "jenkins_vpc_cidr" {
  value = module.vpc_jenkins.vpc_cidr_block
}

output "jenkins_public_subnets" {
  value = module.vpc_jenkins.public_subnets
}

output "jenkins_private_subnets" {
  value = module.vpc_jenkins.private_subnets
}
