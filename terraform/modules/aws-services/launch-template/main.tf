resource "aws_launch_template" "this" {
  name_prefix   = "${var.lt_name_prefix}-lt-"
  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    security_groups             = var.security_group_ids
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.volume_size
      volume_type = var.volume_type
    }
  }

  user_data = base64encode(templatefile(var.user_data_template_path, var.user_data_template_vars))

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name      = "${var.lt_name_prefix}-launch-template"
        Terraform = "true"
        Version   = var.launch_template_version
      },
      var.additional_tags
    )
  }
}