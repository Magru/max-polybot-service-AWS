resource "aws_route_table" "this" {
  vpc_id = var.vpc_id

  dynamic "route" {
    for_each = var.routes
    content {
      cidr_block = route.value.cidr_block
      gateway_id = route.value.gateway_id
    }
  }

  tags = merge(
    {
      Name      = var.route_table_name != "" ? var.route_table_name : "${var.rt_name_prefix}-main-route-table"
      Terraform = "true"
      Version   = var.build_version
    },
    var.additional_tags
  )
}