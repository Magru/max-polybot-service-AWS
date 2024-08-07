resource "aws_iam_role_policy" "this" {
  name = var.policy_name != "" ? var.policy_name : "${var.iamrp_name_prefix}-${var.policy_name_suffix}"
  role = var.role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = var.policy_statements
  })
}