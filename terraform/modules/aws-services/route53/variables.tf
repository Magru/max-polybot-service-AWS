variable "zone_id" {
  description = "The ID of the hosted zone to contain this record."
  type        = string
}

variable "subdomain_name" {
  description = "The name of the subdomain."
  type        = string
}

variable "target_dns_name" {
  description = "The DNS name of the load balancer or other target."
  type        = string
}

variable "target_zone_id" {
  description = "The ID of the target's hosted zone."
  type        = string
}

variable "evaluate_target_health" {
  description = "Whether or not to evaluate the health of the alias target."
  type        = bool
  default     = true
}
