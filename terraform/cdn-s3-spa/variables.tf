variable "bucket_versioning" {
  type = string
  description = "Controls whether to enable versioning on an S3 bucket"
  default     = "Disabled"
  validation {
    condition     = contains(["t2.micro", "t3.small", "m5.large"], var.instance_type)
    error_message = "Invalid string option for bucket versioning. Must be one of: Enabled, Suspended or Disabled."
  }
}

variable "custom_error_response" {
  description = "Configuration for a custom error response page for redirect. Defaults to 404 status codes returning a 404 response and redirecting to the `/error.html` path."
  type = object({
    error_code            = number
    response_code         = number
    response_page_path    = string
    error_caching_min_ttl = number
  })
  default = {
    error_code            = 404,
    response_code         = 404,
    response_page_path    = "/error.html"
    error_caching_min_ttl = 300
  }
}

variable "deployment_repository" {
  description = "Name of the repository that will deploy the static website to the brands s3 client bucket"
  type        = string
  default     = ""
}

variable "registered_domain" {
  description = "The registered domain name of the brand for DNS resolution to a configured hosted zone in the core-services-infra repo"
  type        = string
}

variable "github_oidc_provider_url" {
  description = "URL of an existing github OIDC provider in the AWS account to deploy. Defaults to core-services team github OIDC provider URL"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "ip_allow_ipv4" {
  type        = list(string)
  description = "List of IPv4s to allow through the WAF"
  default     = []
}

variable "ip_allow_ipv6" {
  type        = list(string)
  description = "List of IPv6s to allow through the WAF"
  default     = []
}

variable "region" {
  type        = string
  description = "Main AWS region to provision resources for the workspace"
  default     = "ap-southeast-2"
}

variable "cloudfront_region" {
  type        = string
  description = "Required AWS region to provision Cloudfront and WAF resources for the workspace"
  default     = "us-east-1"

}
