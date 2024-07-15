terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.55"
    }
  }
  backend "s3" {
    bucket         = "max-tf-backend"
    key            = "max-aws-project-tf-state.json"
    region         = "eu-west-2"
    encrypt        = true
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "project-main-vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Terraform = "true"
    Name = "${var.project_name_prefix}-main-vpc"
    version = var.app_server_instance_build_version
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.project-main-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Terraform = "true"
    Name = "${var.project_name_prefix}-subnet-eu-west-2a"
    version = var.app_server_instance_build_version
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.project-main-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Terraform = "true"
    Name = "${var.project_name_prefix}-subnet-eu-west-2b"
    version = var.app_server_instance_build_version
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.project-main-vpc.id
  tags = {
    Terraform = "true"
    Name = "${var.project_name_prefix}-main-gateway"
    version = var.app_server_instance_build_version
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.project-main-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Terraform = "true"
    Name = "${var.project_name_prefix}-main-route-table"
    version = var.app_server_instance_build_version
  }
}

resource "aws_route_table_association" "subnet_a_association" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "subnet_b_association" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "combined_sg" {
  name        = "${var.project_name_prefix}-sg"
  description = "Security group to allow SSH, HTTPS, and custom TCP traffic"
  vpc_id      = aws_vpc.project-main-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.project-main-vpc.cidr_block]
  }

  tags = {
    Terraform = "true"
    Name      = "${var.project_name_prefix}-combined_sg"
    version   = var.app_server_instance_build_version
  }
}


resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name_prefix}-ec2_full_s3_secrets_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_role_policy" {
  name = "${var.project_name_prefix}-ec2_full_s3_secrets_sqs_dynamodb_policy"
  role = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid    = "SQSPermissions"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
        ]
        Resource = "arn:aws:sqs:eu-west-2:019273956931:max-aws-project-sqs.fifo"
      },
      {
        Sid    = "DynamoDBPermissions"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:eu-west-2:019273956931:table/${var.dynamodb_table_name}"
      }
    ]
  })
}


resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name_prefix}-ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app_server" {
  ami           = var.app_server_instance_aim
  instance_type = var.app_server_instance_type
  key_name      = var.app_server_instance_kp_name
  subnet_id              = aws_subnet.subnet_a.id
  vpc_security_group_ids = [aws_security_group.combined_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  associate_public_ip_address = true
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 12
    volume_type = "gp2"
  }

  user_data = file("./deploy.sh")

  tags = {
    Name      = "${var.project_name_prefix}-polybot-a"
    Terraform = "true"
    version = var.app_server_instance_build_version
  }

  depends_on = [aws_security_group.combined_sg]
}

resource "aws_instance" "app_server_2" {
  ami           = var.app_server_instance_aim
  instance_type = var.app_server_instance_type
  key_name      = var.app_server_instance_kp_name
  subnet_id              = aws_subnet.subnet_b.id
  vpc_security_group_ids = [aws_security_group.combined_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  associate_public_ip_address = true
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 12
    volume_type = "gp2"
  }

  user_data = file("./deploy.sh")

  tags = {
    Name      = "${var.project_name_prefix}-polybot-b"
    Terraform = "true"
    version = var.app_server_instance_build_version
  }

  depends_on = [aws_security_group.combined_sg]
}

resource "aws_iam_role" "asg_role" {
  name = "${var.project_name_prefix}-asg-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "asg_role_policy" {
  name = "${var.project_name_prefix}-asg-role-policy"
  role = aws_iam_role.asg_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
        Resource = "arn:aws:dynamodb:eu-west-2:019273956931:table/${var.dynamodb_table_name}"
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
  })
}

resource "aws_iam_instance_profile" "asg_instance_profile" {
  name = "${var.project_name_prefix}-asg-instance-profile"
  role = aws_iam_role.asg_role.name
}

resource "aws_launch_template" "max-aws-asg" {
  name_prefix   = "${var.project_name_prefix}-lt-"
  image_id      = var.app_server_instance_aim
  instance_type = var.yolo5_server_instance_type
  key_name      = var.app_server_instance_kp_name

  iam_instance_profile {
    name = aws_iam_instance_profile.asg_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.combined_sg.id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 25
      volume_type = "gp2"
    }
  }

#   user_data = base64encode(file("./deploy-yolo5-asg.sh"))
  user_data = base64encode(templatefile("${path.module}/templates/deploy-yolo5-asg.tpl", {
    yolo5_img_name      = var.yolo5_img_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name      = "${var.project_name_prefix}-launch-template"
      Terraform = "true"
      version = var.asg_launch_version
    }
  }
}

module "autoscaling_group" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "${var.project_name_prefix}-asg"
  create_launch_template = false
  launch_template_id = aws_launch_template.max-aws-asg.id
  launch_template_version = var.asg_launch_version
  #1
  desired_capacity = 0
  #1
  min_size = 0
  #2
  max_size = 0
  vpc_zone_identifier = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  tags = {
    Name      = "${var.project_name_prefix}-autoscaling-group"
    Terraform = "true"
  }
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

output "app_server_instance_ip" {
  value = aws_instance.app_server.public_ip
}

output "app_server_2_instance_ip" {
  value = aws_instance.app_server_2.public_ip
}

#TODO: DynamoDB, SQS