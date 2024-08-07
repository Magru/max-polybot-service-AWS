variable "vpc_id" {
  description = "The VPC ID where the Route Table will be created"
  type        = string
}

variable "routes" {
  description = "A list of route definitions to add to the route table"
  type = list(object({
    cidr_block = string
    gateway_id = string
  }))
  default = []
}

variable "rt_name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "build_version" {
  description = "The build version tag to apply to the Route Table"
  type        = string
}

variable "route_table_name" {
  description = "Optional custom name for the Route Table. If not provided, a name will be generated."
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to add to the Route Table"
  type        = map(string)
  default     = {}
}