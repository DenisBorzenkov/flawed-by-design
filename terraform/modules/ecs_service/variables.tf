variable "name" {
  type = string
}

variable "env" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "cpu" {
  type = number
}

variable "memory" {
  type = number
}

variable "image" {
  type = string
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "log_group_name" {
  type = string
}

variable "region" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "listener_arn" {
  type = string
}

variable "listener_priority" {
  type = number
}

variable "host_header" {
  type = string
}

variable "health_check_path" {
  type    = string
  default = "/healthz"
}

variable "container_health_check" {
  description = "Container-level (Docker) health check tuning. Defaults are production-safe (cold-start absorbed by 30s startPeriod, three failures before unhealthy)."
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

variable "network_mode" {
  description = "ECS task network mode. bridge supports dynamic host ports for >1 task per instance."
  type        = string
  default     = "bridge"
}

variable "deployment_minimum_healthy_percent" {
  type    = number
  default = 50
}

variable "deployment_maximum_percent" {
  type    = number
  default = 200
}

variable "placement_strategy_type" {
  type    = string
  default = "spread"
}

variable "placement_strategy_field" {
  type    = string
  default = "attribute:ecs.availability-zone"
}
