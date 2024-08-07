variable "lt_name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "image_id" {
  description = "The AMI ID to use for the instance"
  type        = string
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
}

variable "key_name" {
  description = "The key name of the Key Pair to use for the instance"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "The name of the IAM instance profile"
  type        = string
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with an instance in a VPC"
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
}

variable "volume_size" {
  description = "The size of the volume in gigabytes"
  type        = number
  default     = 25
}

variable "volume_type" {
  description = "The type of volume. Can be 'standard', 'gp2', or 'io1'"
  type        = string
  default     = "gp2"
}

variable "user_data_template_path" {
  description = "The path to the user data template file"
  type        = string
}

variable "user_data_template_vars" {
  description = "A map of variables to pass to the user data template"
  type        = map(string)
  default     = {}
}

variable "launch_template_version" {
  description = "The version of the launch template"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags to add to the launch template"
  type        = map(string)
  default     = {}
}