variable "zone_id" {
  description = "The Route53 zone ID to add the record to."
  type        = string
}

variable "subdomain_name" {
  description = "The subdomain name to request a certificate for."
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}
