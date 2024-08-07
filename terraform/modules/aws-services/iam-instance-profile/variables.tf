variable "iamip_name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "profile_name" {
  description = "The name of the IAM instance profile. If not provided, it will be generated using the project_name_prefix and profile_name_suffix"
  type        = string
  default     = ""
}

variable "profile_name_suffix" {
  description = "A suffix to add to the profile name when using the default naming convention"
  type        = string
  default     = "instance_profile"
}

variable "role_name" {
  description = "The name of the IAM role to associate with this instance profile"
  type        = string
}

variable "build_version" {
  description = "The build version tag to apply to the IAM Instance Profile"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags to add to the IAM Instance Profile"
  type        = map(string)
  default     = {}
}