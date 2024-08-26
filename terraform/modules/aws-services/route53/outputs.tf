output "subdomain_name" {
  description = "The name of the created subdomain."
  value       = aws_route53_record.subdomain.name
}
