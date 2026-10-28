variable "aws_region" {
  description = "AWS region used for shared global-service API calls."
  type        = string
  default     = "ap-northeast-2"
}

variable "root_domain_name" {
  description = "Registered root domain managed by Route 53."
  type        = string
  default     = "un-box.click"
}

variable "tags" {
  description = "Additional tags for shared resources."
  type        = map(string)
  default = {
    Owner = "LANDERAI"
  }
}
