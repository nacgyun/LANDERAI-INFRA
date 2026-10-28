variable "project_name" {
  description = "Project name used as a resource prefix."
  type        = string
}

variable "frontend_domain_name" {
  description = "Frontend domain used by the error page's home link."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "base_domain" {
  description = "Base domain below which user site subdomains are served."
  type        = string
}

variable "acm_certificate_arn" {
  description = "Wildcard ACM certificate ARN in us-east-1."
  type        = string
}

variable "tags" {
  description = "Tags applied to user hosting resources."
  type        = map(string)
  default     = {}
}
