variable "project_name" {
  description = "Project name used as a resource prefix."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "tags" {
  description = "Additional tags for resources."
  type        = map(string)
  default     = {}
}

