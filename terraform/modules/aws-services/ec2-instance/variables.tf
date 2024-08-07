variable "ami_id" {
  description = "The AMI to use for the instance"
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

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in"
  type        = string
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "The IAM Instance Profile to launch the instance with"
  type        = string
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with an instance in a VPC"
  type        = bool
  default     = true
}

variable "user_data_replace_on_change" {
  description = "Whether to replace the instance when the user data changes"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "The size of the root volume in gigabytes"
  type        = number
  default     = 12
}

variable "root_volume_type" {
  description = "The type of the root volume"
  type        = string
  default     = "gp2"
}

variable "user_data_file" {
  description = "The path to the user data file"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "The user data to provide when launching the instance"
  type        = string
  default     = ""
}

variable "ec2_name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "instance_name" {
  description = "The name to give the instance"
  type        = string
  default     = ""
}

variable "instance_name_suffix" {
  description = "A suffix to add to the instance name when using the default naming convention"
  type        = string
  default     = "ec2-instance"
}

variable "build_version" {
  description = "The build version tag to apply to the instance"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags to add to the instance"
  type        = map(string)
  default     = {}
}