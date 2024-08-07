resource "aws_iam_instance_profile" "this" {
  name = var.profile_name != "" ? var.profile_name : "${var.iamip_name_prefix}-${var.profile_name_suffix}"
  role = var.role_name

  tags = merge(
    {
      Name      = var.profile_name != "" ? var.profile_name : "${var.iamip_name_prefix}-${var.profile_name_suffix}"
      Terraform = "true"
      Version   = var.build_version
    },
    var.additional_tags
  )
}