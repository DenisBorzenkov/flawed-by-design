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

variable "log_bucket_name_prefix" {
  description = "Prefix for the ALB access-log bucket. Final name: <prefix>-<account>-<env>-<region>."
  type        = string
  default     = "alb-logs"
}

variable "log_bucket_force_destroy" {
  description = "Allow `terraform destroy` to wipe the bucket even if it has objects. Off by default for safety."
  type        = bool
  default     = false
}

variable "log_bucket_versioning_status" {
  description = "Versioning state. Suspended: log objects are write-once, no rollback needed."
  type        = string
  default     = "Suspended"
  validation {
    condition     = contains(["Enabled", "Suspended"], var.log_bucket_versioning_status)
    error_message = "Must be Enabled or Suspended."
  }
}

variable "log_lifecycle" {
  description = "Lifecycle policy for ALB access logs. Tune per compliance retention."
  type = object({
    transition_to_ia_days     = optional(number, 30)
    expiration_days           = optional(number, 90)
    abort_incomplete_mpu_days = optional(number, 7)
    transition_storage_class  = optional(string, "STANDARD_IA")
  })
  default = {}
}

