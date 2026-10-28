variable "project_name" {
  description = "Project name used as a resource prefix."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "workflow_name" {
  description = "Step Functions workflow suffix."
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN used by the state machine."
  type        = string
}

variable "embedding_lambda_arn" {
  description = "Embedding Lambda ARN."
  type        = string
}

variable "design_plan_lambda_arn" {
  description = "Design plan Lambda ARN."
  type        = string
}

variable "landing_page_variant_lambda_arn" {
  description = "Landing page variant Lambda ARN."
  type        = string
}

variable "persist_result_lambda_arn" {
  description = "Persist result Lambda ARN."
  type        = string
}

variable "variant_max_concurrency" {
  description = "Inline Map concurrency. Zero preserves the existing unrestricted behavior."
  type        = number
  default     = 0
  validation {
    condition     = contains([0, 1, 2], var.variant_max_concurrency)
    error_message = "Use 0 (existing default), 1 (sequential), or 2 (parallel A/B)."
  }
}

variable "tags" {
  description = "Additional tags for resources."
  type        = map(string)
  default     = {}
}
