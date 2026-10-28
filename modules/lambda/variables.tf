variable "project_name" {
  description = "Project name used as a resource prefix."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "lambda_name" {
  description = "Lambda function suffix."
  type        = string
}

variable "description" {
  description = "Lambda function description."
  type        = string
  default     = "LANDERAI Lambda managed by Terraform."
}

variable "source_file" {
  description = "Path to the Lambda handler source file."
  type        = string
  default     = null
}

variable "source_dir" {
  description = "Path to the Lambda package source directory."
  type        = string
  default     = null
}

variable "output_path" {
  description = "Path where the packaged Lambda zip will be created."
  type        = string
  default     = null
}

variable "excludes" {
  description = "Patterns excluded from the Lambda zip package."
  type        = list(string)
  default = [
    ".env",
    ".git/**",
    ".local-storage/**",
    ".terraform/**",
    ".venv/**",
    "__pycache__/**",
    "**/__pycache__/**",
    "*.pyc",
    "**/*.pyc",
  ]
}

variable "role_arn" {
  description = "IAM execution role ARN for the Lambda function."
  type        = string
}

variable "handler" {
  description = "Lambda handler."
  type        = string
  default     = "handler.lambda_handler"
}

variable "runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "architectures" {
  description = "Instruction set architectures for the Lambda function."
  type        = list(string)
  default     = ["arm64"]
}

variable "memory_size" {
  description = "Lambda memory size in MB."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 10
}

variable "reserved_concurrent_executions" {
  description = "Maximum reserved concurrency for the function. Use -1 for unreserved concurrency."
  type        = number
  default     = -1
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days."
  type        = number
  default     = 14
}

variable "environment_variables" {
  description = "Additional Lambda environment variables."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags for resources."
  type        = map(string)
  default     = {}
}
