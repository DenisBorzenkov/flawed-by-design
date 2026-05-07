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

// ECS-on-EC2 sizing per brief: t3.micro x2 per cluster.
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "asg_min" {
  type    = number
  default = 2
}

variable "asg_max" {
  type    = number
  default = 4
}

variable "ecs_ami_name_pattern" {
  description = "AMI name filter for the ECS-optimized image."
  type        = string
  default     = "al2023-ami-ecs-hvm-*-x86_64"
}

variable "log_retention_days" {
  description = "Retention for /ecs/<env>/* CloudWatch log groups."
  type        = number
  default     = 14
}

variable "ecr_keep_last_n_images" {
  description = "ECR lifecycle policy retains this many most-recent images per repo."
  type        = number
  default     = 10
}

variable "ecr_image_tag_mutability" {
  description = "MUTABLE so CI can re-push :latest. Use IMMUTABLE for prod with sha tags."
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "Must be MUTABLE or IMMUTABLE."
  }
}

variable "tls_rsa_bits" {
  description = "RSA key length for the throwaway self-signed cert."
  type        = number
  default     = 2048
}

variable "tls_validity_hours" {
  description = "Lifetime of the throwaway self-signed cert."
  type        = number
  default     = 8760
}

variable "capacity_provider_target_capacity" {
  description = "Target percent utilization the ASG should track."
  type        = number
  default     = 100
}

variable "capacity_provider_min_step" {
  description = "Minimum scaling step size for managed scaling."
  type        = number
  default     = 1
}

variable "capacity_provider_max_step" {
  description = "Maximum scaling step size for managed scaling."
  type        = number
  default     = 2
}

variable "deployment_minimum_healthy_percent" {
  description = "ECS rolling deploy: minimum healthy percent."
  type        = number
  default     = 50
}

variable "deployment_maximum_percent" {
  description = "ECS rolling deploy: maximum percent."
  type        = number
  default     = 200
}

variable "app_service" {
  description = "App ECS service sizing. cpu=256/memory=512 lets two tasks bin-pack onto a single t3.micro without forcing the ASG to scale."
  type = object({
    desired_count     = optional(number, 2)
    cpu               = optional(number, 256)
    memory            = optional(number, 512)
    container_port    = optional(number, 8080)
    image_tag         = optional(string, "latest")
    listener_priority = optional(number, 10)
    health_check_path = optional(string, "/health")
  })
  default = {}
}

variable "jenkins_service" {
  description = "Jenkins ECS service sizing."
  type = object({
    desired_count     = optional(number, 1)
    cpu               = optional(number, 512)
    memory            = optional(number, 512)
    container_port    = optional(number, 8080)
    image_tag         = optional(string, "lts")
    listener_priority = optional(number, 10)
    health_check_path = optional(string, "/login")
  })
  default = {}
}

variable "container_health_check" {
  description = "Container-level (Docker) health check. Defaults are production-safe: 30s probe interval, 30s start grace, 5s curl budget, three failures before unhealthy."
  type = object({
    interval_seconds     = optional(number, 30)
    retries              = optional(number, 3)
    start_period_seconds = optional(number, 30)
    timeout_seconds      = optional(number, 5)
  })
  default = {}
}

variable "target_group_health_check" {
  description = "ALB target-group health check tuning."
  type = object({
    interval_seconds     = optional(number, 30)
    timeout_seconds      = optional(number, 5)
    healthy_threshold    = optional(number, 2)
    unhealthy_threshold  = optional(number, 3)
    deregistration_delay = optional(number, 10)
    matcher              = optional(string, "200-299")
  })
  default = {}
}
