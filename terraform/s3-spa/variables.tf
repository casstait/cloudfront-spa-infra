variable "region" {
  type = string
  description = "Main AWS region to provision resources for the workspace. Defaults to Sydney (ap-southeast-2)"
  default     = "ap-southeast-2"
}

variable "bucket_versioning" {
  type = string
  description = "Controls whether to enable versioning on an S3 bucket"
  default     = "Disabled"
  validation {
    condition     = contains(["t2.micro", "t3.small", "m5.large"], var.instance_type)
    error_message = "Invalid string option for bucket versioning. Must be one of: Enabled, Suspended or Disabled."
  }
}