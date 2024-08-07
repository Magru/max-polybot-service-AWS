variable "vpc_id" {
  description = "The VPC ID where the subnet will be created"
  type        = string
}

variable "cidr_block" {
  description = "The IPv4 CIDR block for the subnet"
  type        = string
}

variable "availability_zone" {
  description = "The AZ where the subnet will be created"
  type        = string
}

variable "map_public_ip_on_launch" {
  description = "Specify true to indicate that instances launched into the subnet should be assigned a public IP address"
  type        = bool
  default     = false
}

variable "subnet_name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "build_version" {
  description = "The build version tag to apply to the subnet"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags to add to the subnet"
  type        = map(string)
  default     = {}
}

variable "subnet_name" {
  description = "Optional custom name for the subnet. If not provided, a name will be generated."
  type        = string
  default     = ""
}

variable "subnet_type" {
  description = "The type of subnet (e.g., 'public', 'private')"
  type        = string
  default     = "public"
}
