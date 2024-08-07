variable "iamr_name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "role_name" {
  description = "The name of the IAM role. If not provided, it will be generated using the project_name_prefix and role_name_suffix"
  type        = string
  default     = ""
}

variable "role_name_suffix" {
  description = "A suffix to add to the role name when using the default naming convention"
  type        = string
  default     = "iam_role"
}

variable "assume_role_service" {
  description = "The AWS service that can assume this role"
  type        = string
  default     = "ec2.amazonaws.com"
}

variable "build_version" {
  description = "The build version tag to apply to the IAM Role"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags to add to the IAM Role"
  type        = map(string)
  default     = {}
}