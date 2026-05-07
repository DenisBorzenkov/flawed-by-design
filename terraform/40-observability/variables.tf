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

variable "billing_threshold_usd" {
  description = "EstimatedCharges threshold for the billing alarm."
  type        = number
  default     = 1
}

variable "billing_alarm_period_seconds" {
  description = "Evaluation period for the billing alarm. EstimatedCharges updates infrequently."
  type        = number
  default     = 21600
}

variable "alb_health_alarm" {
  description = "Tuning for ALB HealthyHostCount alarms."
  type = object({
    evaluation_periods = optional(number, 2)
    period_seconds     = optional(number, 60)
    threshold          = optional(number, 1)
  })
  default = {}
}

variable "alb_5xx_alarm" {
  description = "Tuning for ALB 5xx alarms."
  type = object({
    evaluation_periods = optional(number, 1)
    period_seconds     = optional(number, 300)
    threshold          = optional(number, 0)
  })
  default = {}
}

variable "route53_health_check" {
  description = "Route53 external health probe tuning."
  type = object({
    port              = optional(number, 443)
    type              = optional(string, "HTTPS")
    failure_threshold = optional(number, 3)
    request_interval  = optional(number, 30)
    measure_latency   = optional(bool, false)
    app_path          = optional(string, "/healthz")
    jenkins_path      = optional(string, "/login")
  })
  default = {}
}

variable "route53_health_alarm" {
  description = "Tuning for Route53 health-check alarms (us-east-1 only)."
  type = object({
    evaluation_periods = optional(number, 2)
    period_seconds     = optional(number, 60)
  })
  default = {}
}
