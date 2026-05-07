variable "region" {
  description = "Primary AWS region. Single-region by brief."
  type        = string
  default     = "eu-central-1"
  validation {
    condition     = var.region == "eu-central-1"
    error_message = "Brief constrains deployment to eu-central-1."
  }
}

variable "env" {
  description = "Environment short name (e.g. dev, stg, prd)."
  type        = string
}

// Default-tags schema. Wired into the AWS provider via default_tags so
// every taggable resource inherits these without per-resource boilerplate.
//
// Required keys gate cost allocation + ownership signals every multi-team
// org wants:
//   - Environment: dev|stg|prd - drives alarm severity, IAM scoping, etc.
//   - Team:        owning-team alias - used for on-call routing.
//   - CostCenter:  finance code - billed-to chargeback dimension.
//   - ManagedBy:   "terraform" sentinel - flips to "manual" when someone
//                  bypasses IaC; CloudCustodian/Drift jobs alert on it.
//
// Validation block hard-fails an apply where any required key is empty,
// so a missing tag never silently creates resources outside policy.
variable "tags" {
  description = "Default tags applied via provider default_tags. Required keys gate cost allocation + ownership; optional keys carry product metadata."
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

variable "domain_name" {
  description = "Public apex domain; used for ALB hostnames if hosted_zone_id is set."
  type        = string
  default     = "example.invalid"
}

variable "hosted_zone_id" {
  description = "Optional Route53 zone ID. When null, no DNS records are created."
  type        = string
  default     = null
  nullable    = true
}

variable "alarm_email" {
  description = "Email subscribed to the ops SNS topic. Subscription requires manual confirm."
  type        = string
}

variable "ssh_keypair_name" {
  description = "Optional EC2 keypair on ECS instances; null to disable SSH path entirely."
  type        = string
  default     = null
  nullable    = true
}
