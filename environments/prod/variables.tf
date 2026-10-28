variable "aws_region" {
  description = "AWS region where resources will be created."
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name used as a resource prefix."
  type        = string
  default     = "landerai"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Additional tags for all resources."
  type        = map(string)
  default     = {}
}

variable "openai_api_key_parameter_name" {
  description = "SSM Parameter Store name for the OpenAI API key."
  type        = string
  default     = "OPENAI_API_KEY"
}

variable "clerk_secret_key_parameter_name" {
  description = "SSM Parameter Store name for the Clerk secret key."
  type        = string
  default     = "/landerai/prod/CLERK_SECRET_KEY"
}

variable "auth_mode" {
  description = "Authentication mode used by the backend API."
  type        = string
  default     = "clerk"
}

variable "clerk_publishable_key" {
  description = "Clerk publishable key exposed to frontend clients."
  type        = string
  default     = ""
}

variable "clerk_authorized_party" {
  description = "Comma-separated Clerk authorized parties."
  type        = string
  default     = ""
}

variable "landing_page_html_bucket_name" {
  description = "S3 bucket name used to store generated landing page HTML. Leave empty to derive one."
  type        = string
  default     = ""
}

variable "landing_page_html_public_base_url" {
  description = "Optional public base URL for generated HTML. Leave empty to use S3 URIs and presigned preview URLs."
  type        = string
  default     = ""
}

variable "s3_vector_bucket_name" {
  description = "S3 Vector bucket name used for selected design plan embeddings."
  type        = string
  default     = "landerai-designplan-vector"
}

variable "s3_vector_index_name" {
  description = "Optional fixed S3 Vector index name. Leave empty to derive one from industry, such as cafe-index."
  type        = string
  default     = ""
}

variable "github_actions_repository" {
  description = "GitHub repository allowed to assume the Lambda deployment role, in owner/repo format."
  type        = string
  default     = "nacgyun/LANDERAI-BE"
}

variable "github_actions_frontend_subject_repository" {
  description = "Repository identity used in GitHub's customized OIDC subject, including immutable owner and repository IDs."
  type        = string
  default     = "nacgyun@49582192/LANDERAI-FE@1317108782"
}

variable "root_domain_name" {
  description = "Route 53 public hosted zone used for frontend DNS."
  type        = string
  default     = "un-box.click"
}

variable "frontend_domain_name" {
  description = "Custom domain name for the prod frontend."
  type        = string
  default     = "landerai.un-box.click"
}

variable "user_hosting_base_domain" {
  description = "Base domain for user-hosted landing page subdomains."
  type        = string
  default     = "landerai.un-box.click"
}
