variable "project_name" {
  description = "Project name used as a resource prefix."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "api_name" {
  description = "API Gateway name suffix."
  type        = string
  default     = "api"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function integrated with API Gateway."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function integrated with API Gateway."
  type        = string
}

variable "cors_allow_headers" {
  description = "Allowed CORS headers."
  type        = list(string)
  default     = ["content-type", "authorization"]
}

variable "cors_allow_methods" {
  description = "Allowed CORS methods."
  type        = list(string)
  default     = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
}

variable "cors_allow_origins" {
  description = "Allowed CORS origins."
  type        = list(string)
  default     = ["*"]
}

variable "cors_max_age" {
  description = "CORS preflight cache max age in seconds."
  type        = number
  default     = 300
}

variable "tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}
