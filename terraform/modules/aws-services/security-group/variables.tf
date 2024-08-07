
variable "vpc_id" {
  description = "The VPC ID where the Security Group will be created"
  type        = string
}

variable "sg_name" {
  description = "The name of the security group"
  type        = string
  default     = ""
}

variable "sg_description" {
  description = "The description of the security group"
  type        = string
}

variable "sg_name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "build_version" {
  description = "The build version tag to apply to the Security Group"
  type        = string
}

variable "ingress_rules" {
  description = "List of ingress rules to create by name"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules to create by name"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "additional_tags" {
  description = "Additional tags to add to the Security Group"
  type        = map(string)
  default     = {}
}