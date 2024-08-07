locals {
  subnet_name = var.subnet_name != "" ? var.subnet_name : "${var.subnet_name_prefix}-${var.subnet_type}-${var.availability_zone}"
}

resource "aws_subnet" "this" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    {
      Name       = local.subnet_name
      Terraform  = "true"
      Version    = var.build_version
      SubnetType = var.subnet_type
    },
    var.additional_tags
  )
}