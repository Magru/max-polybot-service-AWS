variable "region" {
  description = "Deployment region"
  type        = string
}
variable "app_server_instance_type" {
  description = "App server instance type"
  type        = string
}
variable "yolo5_server_instance_type" {
  description = "Yolo5 server instance type"
  type        = string
}
variable "app_server_instance_aim" {
  description = "Instance AIM"
  type        = string
}
variable "app_server_instance_kp_name" {
  description = "Instance Key Pair name"
  type        = string
}
variable "project_name_prefix" {
  description = "Project resources name prefix"
  type        = string
}
variable "app_server_instance_build_version" {
  description = "Build version"
  type        = string
}
variable "dynamodb_table_name" {
  description = "DynamoDB Table Name"
  type        = string
}
variable "asg_launch_version" {
  description = "Auto Scale Group Launch template version"
  type        = string
}