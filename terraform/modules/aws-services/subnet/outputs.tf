output "subnet_id" {
  description = "The ID of the subnet"
  value       = aws_subnet.this.id
}

output "subnet_arn" {
  description = "The ARN of the subnet"
  value       = aws_subnet.this.arn
}

output "subnet_cidr_block" {
  description = "The CIDR block of the subnet"
  value       = aws_subnet.this.cidr_block
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = local.subnet_name
}