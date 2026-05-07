variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "env" {
  type = string
}

// 10-network has no upstream state reads, so `tfstate_bucket` is not
// declared here. The shared per-account tfvars still passes it; Terraform
// emits a benign "undeclared variable" warning that deploy.sh swallows
// with -compact-warnings.

variable "tags" {
  description = "Default tags applied via provider default_tags. See 00-providers/variables.tf for full schema commentary."
  type = object({
    Environment = string
    Team        = string
    CostCenter  = string
    ManagedBy   = string
    Product     = optional(string, "cloud-platform")
    Service     = optional(string, "pipeline")
  })
  validation {
    condition = alltrue([
      length(var.tags.Environment) > 0,
      length(var.tags.Team) > 0,
      length(var.tags.CostCenter) > 0,
      length(var.tags.ManagedBy) > 0,
    ])
    error_message = "tags.Environment, .Team, .CostCenter, and .ManagedBy must all be non-empty."
  }
}

variable "azs" {
  description = "AZs to span. null = first two AZs of var.region (region+a, region+b)."
  type        = list(string)
  default     = null
  nullable    = true
}

variable "app_vpc_cidr" {
  description = "CIDR for the app-tier VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "app_public_subnet_cidrs" {
  description = "Public subnet CIDRs in the app VPC (one per AZ)."
  type        = list(string)
  default     = ["10.40.0.0/24", "10.40.1.0/24"]
}

variable "app_private_subnet_cidrs" {
  description = "Private subnet CIDRs in the app VPC (one per AZ)."
  type        = list(string)
  default     = ["10.40.10.0/24", "10.40.11.0/24"]
}

variable "jenkins_vpc_cidr" {
  description = "CIDR for the jenkins-tier VPC."
  type        = string
  default     = "10.41.0.0/16"
}

variable "jenkins_public_subnet_cidrs" {
  description = "Public subnet CIDRs in the jenkins VPC (one per AZ)."
  type        = list(string)
  default     = ["10.41.0.0/24", "10.41.1.0/24"]
}

variable "jenkins_private_subnet_cidrs" {
  description = "Private subnet CIDRs in the jenkins VPC (one per AZ)."
  type        = list(string)
  default     = ["10.41.10.0/24", "10.41.11.0/24"]
}

variable "interface_endpoints" {
  description = "AWS interface endpoints required for ECS-on-EC2 in private subnets without NAT."
  type        = list(string)
  default = [
    "ecr.api",
    "ecr.dkr",
    "logs",
    "ssm",
    "ecs",
    "ecs-agent",
    "ecs-telemetry",
  ]
}
