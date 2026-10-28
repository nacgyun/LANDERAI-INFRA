variable "project_name" {
  description = "Project name used as a resource prefix."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "tags" {
  description = "Tags applied to frontend hosting resources."
  type        = map(string)
  default     = {}
}

variable "aliases" {
  description = "Custom domain names served by the CloudFront distribution."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront custom domains."
  type        = string
  default     = null
  nullable    = true
}
