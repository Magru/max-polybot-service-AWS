resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.iam_instance_profile
  associate_public_ip_address = var.associate_public_ip_address
  user_data_replace_on_change = var.user_data_replace_on_change

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  user_data = var.user_data_file != "" ? file(var.user_data_file) : var.user_data

  tags = merge(
    {
      Name      = var.instance_name != "" ? var.instance_name : "${var.ec2_name_prefix}-${var.instance_name_suffix}"
      Terraform = "true"
      Version   = var.build_version
    },
    var.additional_tags
  )
}