resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = merge(
    {
      Name      = var.gateway_name != "" ? var.gateway_name : "${var.igw_name_prefix}-main-gateway"
      Terraform = "true"
      Version   = var.build_version
    },
    var.additional_tags
  )
}