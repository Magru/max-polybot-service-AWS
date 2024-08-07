output "instance_profile_id" {
  description = "The ID of the IAM instance profile"
  value       = aws_iam_instance_profile.this.id
}

output "instance_profile_arn" {
  description = "The ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.this.arn
}

output "instance_profile_name" {
  description = "The name of the IAM instance profile"
  value       = aws_iam_instance_profile.this.name
}
