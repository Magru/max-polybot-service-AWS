variable "iamrp_name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "policy_name" {
  description = "The name of the IAM role policy. If not provided, it will be generated using the project_name_prefix and policy_name_suffix"
  type        = string
  default     = ""
}

variable "policy_name_suffix" {
  description = "A suffix to add to the policy name when using the default naming convention"
  type        = string
  default     = "role_policy"
}

variable "role_id" {
  description = "The ID of the IAM role to which this policy should be attached"
  type        = string
}

variable "policy_statements" {
  description = "A list of policy statement objects"
  type        = any
}