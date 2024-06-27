terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.53"
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
        Resource = "arn:aws:dynamodb:eu-west-2:019273956931:table/your-dynamodb-table-name"
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

  user_data = file("./deploy.sh")

  tags = {
    Name      = "${var.project_name_prefix}-polybot-b"
    Terraform = "true"
    version = var.app_server_instance_build_version
  }

  depends_on = [aws_security_group.combined_sg]
}

output "app_server_instance_ip" {
  value = aws_instance.app_server.public_ip
}

output "app_server_2_instance_ip" {
  value = aws_instance.app_server_2.public_ip
}
