variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "env" {
  type = string
}

variable "tfstate_bucket" {
  description = "S3 bucket holding terraform_remote_state. Created by accounts/_bootstrap."
  type        = string
}

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

variable "allowed_country_codes" {
  description = "WAFv2 geo-match allow-list. Brief locks Jenkins to Portugal."
  type        = list(string)
  default     = ["PT"]
}
