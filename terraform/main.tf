terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.55"
    }
  }
  backend "s3" {
    bucket  = "max-tf-backend"
    key     = "max-aws-project-tf-state.json"
    region  = "eu-west-2"
    encrypt = true
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_count = min(var.max_az_count, length(data.aws_availability_zones.available.names))
  subnet_cidr_blocks = [
    for i in range(length(data.aws_availability_zones.available.names)) :
    cidrsubnet(module.main_vpc.vpc_cidr_block, 8, i)
  ]
}

module "dynamodb_table" {
  source = "./modules/aws-services/dynamodb"

  table_name    = "${var.project_name_prefix}-table"
  billing_mode  = "PAY_PER_REQUEST"
  hash_key      = "prediction_id"
  hash_key_type = "S"

  attributes = [
    {
      name = "prediction_id"
      type = "S"
    },
    {
      name = "chat_id"
      type = "S"
    },
    {
      name = "labels"
      type = "S"
    },
    {
      name = "predicted_img_path"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name               = "ChatIdIndex"
      hash_key           = "chat_id"
      range_key          = "prediction_id"
      projection_type    = "ALL"
      non_key_attributes = []
    },
    {
      name               = "LabelsIndex"
      hash_key           = "labels"
      range_key          = "prediction_id"
      projection_type    = "ALL"
      non_key_attributes = []
    },
    {
      name               = "ImagePathIndex"
      hash_key           = "predicted_img_path"
      range_key          = "prediction_id"
      projection_type    = "ALL"
      non_key_attributes = []
    }
  ]

  tags = {
    Environment = "Production"
    Owner       = "DevOps Terraform project"
    Terraform   = "true"
    Version     = var.project_build_version
  }
}
output "db_table_name" {
  value = module.dynamodb_table.table_name
}

module "main_vpc" {
  source = "./modules/aws-services/vpc"

  cidr_block      = "10.0.0.0/16"
  build_version   = var.project_build_version
  vpc_name_prefix = "${var.project_name_prefix}-main-vpc"

  additional_tags = {
    Owner = "DevOps Terraform project"
  }
}

module "public_subnets" {
  source = "./modules/aws-services/subnet"
  count  = local.az_count

  vpc_id                  = module.main_vpc.vpc_id
  cidr_block              = local.subnet_cidr_blocks[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  subnet_name_prefix      = var.project_name_prefix
  build_version           = var.project_build_version
  subnet_type             = "public"

  additional_tags = {
    Owner       = "DevOps Terraform project"
    SubnetIndex = count.index
  }
}
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.public_subnets[*].subnet_id
}
output "public_subnet_names" {
  description = "List of public subnet names"
  value       = module.public_subnets[*].subnet_name
}
output "subnet_azs" {
  description = "List of subnet Availability Zones"
  value       = data.aws_availability_zones.available.names
}

module "internet_gateway" {
  source = "./modules/aws-services/internet-gateway"

  vpc_id          = module.main_vpc.vpc_id
  igw_name_prefix = var.project_name_prefix
  build_version   = var.project_build_version

  additional_tags = {
    Owner = "DevOps Terraform project"
  }
}
output "internet_gateway_id" {
  value = module.internet_gateway.internet_gateway_id
}

module "main_route_table" {
  source = "./modules/aws-services/route-table"

  vpc_id         = module.main_vpc.vpc_id
  rt_name_prefix = var.project_name_prefix
  build_version  = var.project_build_version

  routes = [
    {
      cidr_block = "0.0.0.0/0"
      gateway_id = module.internet_gateway.internet_gateway_id
    }
  ]

  additional_tags = {
    Owner = "DevOps Terraform project"
  }
}
output "main_route_table_id" {
  value = module.main_route_table.route_table_id
}

resource "aws_route_table_association" "public_subnet_associations" {
  count = local.az_count

  subnet_id      = module.public_subnets[count.index].subnet_id
  route_table_id = module.main_route_table.route_table_id
}

module "combined_sg" {
  source = "./modules/aws-services/security-group"

  vpc_id         = module.main_vpc.vpc_id
  sg_name        = "${var.project_name_prefix}-combined-sg"
  sg_description = "Security group to allow SSH, HTTPS, and custom TCP traffic"
  sg_name_prefix = var.project_name_prefix
  build_version  = var.project_build_version

  ingress_rules = [
    {
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port = 8443
      to_port   = 8443
      protocol  = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
      cidr_blocks = [module.main_vpc.vpc_cidr_block]
    }
  ]

  egress_rules = [
    {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  additional_tags = {
    Owner = "DevOps Terraform project"
  }
}
output "combined_sg_id" {
  value = module.combined_sg.security_group_id
}

module "ec2_role" {
  source = "./modules/aws-services/iam-role"

  iamr_name_prefix    = var.project_name_prefix
  role_name_suffix    = "ec2_full_s3_secrets_role"
  assume_role_service = "ec2.amazonaws.com"
  build_version       = var.project_build_version

  additional_tags = {
    Owner = "DevOps Terraform project"
  }
}

module "ec2_role_policy" {
  source = "./modules/aws-services/iam-role-policy"

  iamrp_name_prefix  = var.project_name_prefix
  policy_name_suffix = "ec2_full_s3_secrets_sqs_dynamodb_policy"
  role_id            = module.ec2_role.role_id

  policy_statements = [
    {
      Action = ["s3:*"]
      Effect   = "Allow"
      Resource = "*"
    },
    {
      Action = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Effect   = "Allow"
      Resource = "*"
    },
    {
      Sid      = "SQSPermissions"
      Effect   = "Allow"
      Action = ["sqs:SendMessage"]
      Resource = "arn:aws:sqs:eu-west-2:019273956931:max-aws-project-sqs.fifo"
    },
    {
      Sid      = "DynamoDBPermissions"
      Effect   = "Allow"
      Action = ["dynamodb:GetItem", "dynamodb:BatchGetItem", "dynamodb:Query", "dynamodb:Scan"]
      Resource = "arn:aws:dynamodb:eu-west-2:019273956931:table/${module.dynamodb_table.table_name}"
    }
  ]
}

module "ec2_instance_profile" {
  source = "./modules/aws-services/iam-instance-profile"

  iamip_name_prefix   = var.project_name_prefix
  profile_name_suffix = "ec2_instance_profile"
  role_name           = module.ec2_role.role_name
  build_version       = var.project_build_version
}
output "ec2_role_arn" {
  value = module.ec2_role.role_arn
}
output "ec2_instance_profile_arn" {
  value = module.ec2_instance_profile.instance_profile_arn
}

module "app_servers" {
  source = "./modules/aws-services/ec2-instance"
  count  = local.az_count

  ami_id                      = var.app_server_instance_ami
  instance_type               = var.app_server_instance_type
  key_name                    = var.app_server_instance_kp_name
  subnet_id                   = module.public_subnets[count.index].subnet_id
  security_group_ids = [module.combined_sg.security_group_id]
  iam_instance_profile        = module.ec2_instance_profile.instance_profile_name
  associate_public_ip_address = true
  user_data_replace_on_change = true
  root_volume_size            = 12
  root_volume_type            = "gp2"
  user_data_file              = "./deploy.sh"
  ec2_name_prefix             = var.project_name_prefix
  instance_name_suffix        = "polybot-${data.aws_availability_zones.available.names[count.index]}"
  build_version               = var.project_build_version

  additional_tags = {
    Role        = "Application Server"
    SubnetIndex = count.index
    AZ          = data.aws_availability_zones.available.names[count.index]
  }
}
output "app_server_public_ips" {
  description = "Public IPs of the application servers"
  value       = module.app_servers[*].instance_public_ip
}
output "app_server_private_ips" {
  description = "Private IPs of the application servers"
  value       = module.app_servers[*].instance_private_ip
}
output "app_server_ids" {
  description = "IDs of the application servers"
  value       = module.app_servers[*].instance_id
}

module "asg_role" {
  source = "./modules/aws-services/iam-role"

  iamr_name_prefix    = var.project_name_prefix
  role_name_suffix    = "asg-role"
  assume_role_service = "ec2.amazonaws.com"
  build_version       = var.project_build_version

  additional_tags = {
    Purpose = "Auto Scaling Group"
  }
}
output "asg_role_arn" {
  description = "The ARN of the ASG IAM role"
  value       = module.asg_role.role_arn
}
output "asg_role_name" {
  description = "The name of the ASG IAM role"
  value       = module.asg_role.role_name
}

module "asg_role_policy" {
  source = "./modules/aws-services/iam-role-policy"

  iamrp_name_prefix  = var.project_name_prefix
  policy_name_suffix = "asg-role-policy"
  role_id            = module.asg_role.role_id

  policy_statements = [
    {
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      Resource = "arn:aws:sqs:eu-west-2:019273956931:max-aws-project-sqs.fifo"
    },
    {
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:GetItem"
      ]
      Resource = "arn:aws:dynamodb:eu-west-2:019273956931:table/${module.dynamodb_table.table_name}"
    },
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      Resource = "arn:aws:s3:::max-yolo5/*"
    }
  ]
}
output "asg_role_policy_id" {
  description = "The ID of the ASG IAM role policy"
  value       = module.asg_role_policy.policy_id
}
output "asg_role_policy_name" {
  description = "The name of the ASG IAM role policy"
  value       = module.asg_role_policy.policy_name
}

module "asg_instance_profile" {
  source = "./modules/aws-services/iam-instance-profile"

  iamip_name_prefix   = var.project_name_prefix
  profile_name_suffix = "asg-instance-profile"
  role_name           = module.asg_role.role_name
  build_version       = var.project_build_version
}
output "asg_instance_profile_arn" {
  value = module.asg_instance_profile.instance_profile_arn
}

module "autoscaling_group" {
  source = "terraform-aws-modules/autoscaling/aws"

  name                    = "${var.project_name_prefix}-asg"
  create_launch_template  = true

  launch_template_name = "${var.project_name_prefix}-launch-template"
  image_id             = var.app_server_instance_ami
  instance_type        = var.yolo5_server_instance_type
  key_name             = var.app_server_instance_kp_name
  iam_instance_profile_name = module.asg_instance_profile.instance_profile_name
#   associate_public_ip_address = true
#   security_group_ids = [module.combined_sg.security_group_id]

  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [module.combined_sg.security_group_id]
    }
  ]

  block_device_mappings = [{
    device_name = "/dev/sda1"
    ebs = {
      volume_size = 25
      volume_type = "gp2"
    }
  }]

  user_data = base64encode(templatefile("${path.module}/templates/deploy-yolo5-asg.tpl", {
    yolo5_img_name      = var.yolo5_img_name
  }))

  desired_capacity = 0 #1
  min_size = 0 #1
  max_size = 0 #2
  vpc_zone_identifier = [module.public_subnets[0].subnet_id, module.public_subnets[1].subnet_id]

  tags = {
    Name      = "${var.project_name_prefix}-autoscaling-group"
    Terraform = "true"
    Owner     = "DevOps Terraform project"
  }
}
output "launch_template_id" {
  value = module.autoscaling_group.launch_template_id
}
output "launch_template_latest_version" {
  value = module.autoscaling_group.launch_template_latest_version
}
output "launch_template_name" {
  value = module.autoscaling_group.launch_template_name
}
output "autoscaling_group_id" {
  value = module.autoscaling_group.autoscaling_group_id
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name_prefix}-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 60

  dimensions = {
    AutoScalingGroupName = module.autoscaling_group.autoscaling_group_id
  }

  alarm_description = "This metric monitors EC2 CPU utilization"
  tags = {
    Terraform = "true"
    Name      = "${var.project_name_prefix}-cpu-high-alarm"
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.project_name_prefix}-scale-out"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = module.autoscaling_group.autoscaling_group_name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

#TODO: DynamoDB, SQS, ALB