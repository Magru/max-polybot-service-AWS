variable "vpc_id" {
  description = "The VPC ID where the Internet Gateway will be created"
  type        = string
}

variable "igw_name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "build_version" {
  description = "The build version tag to apply to the Internet Gateway"
  type        = string
}

variable "gateway_name" {
  description = "Optional custom name for the Internet Gateway. If not provided, a name will be generated."
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to add to the Internet Gateway"
  type        = map(string)
  default     = {}
}