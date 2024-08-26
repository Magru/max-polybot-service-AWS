output "certificate_arn" {
  description = "The ARN of the certificate."
  value       = aws_acm_certificate.certificate.arn
}