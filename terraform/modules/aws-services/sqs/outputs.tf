# modules/aws-services/sqs/outputs.tf

output "queue_id" {
  description = "The SQS Queue ID"
  value       = aws_sqs_queue.this.id
}

output "queue_arn" {
  description = "The SQS Queue ARN"
  value       = aws_sqs_queue.this.arn
}

output "queue_url" {
  description = "The SQS Queue URL"
  value       = aws_sqs_queue.this.url
}
