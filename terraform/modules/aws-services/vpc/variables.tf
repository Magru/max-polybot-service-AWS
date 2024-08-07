variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "vpc_name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "build_version" {
  description = "The build version of the app server instance"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags to add to the VPC"
  type        = map(string)
  default     = {}
}