variable "project_name" {
  type        = string
  description = "Project name used as a resource prefix."
}

variable "environment" {
  type        = string
  description = "Deployment environment name."
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "Time a received revision message remains invisible."
  default     = 1800
}

variable "max_receive_count" {
  type        = number
  description = "Number of processing attempts before a message moves to the DLQ."
  default     = 3
}

variable "tags" {
  type        = map(string)
  description = "Additional tags for resources."
  default     = {}
}
