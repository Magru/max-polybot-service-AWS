output "policy_id" {
  description = "The ID of the IAM role policy"
  value       = aws_iam_role_policy.this.id
}

output "policy_name" {
  description = "The name of the IAM role policy"
  value       = aws_iam_role_policy.this.name
}