output "route_table_id" {
  description = "The ID of the Route Table"
  value       = aws_route_table.this.id
}

output "route_table_arn" {
  description = "The ARN of the Route Table"
  value       = aws_route_table.this.arn
}