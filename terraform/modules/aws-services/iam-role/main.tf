resource "aws_iam_role" "this" {
  name = var.role_name != "" ? var.role_name : "${var.iamr_name_prefix}-${var.role_name_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = var.assume_role_service
        }
      }
    ]
  })

  tags = merge(
    {
      Name      = var.role_name != "" ? var.role_name : "${var.iamr_name_prefix}-${var.role_name_suffix}"
      Terraform = "true"
      Version   = var.build_version
    },
    var.additional_tags
  )
}