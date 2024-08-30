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
variable "app_server_instance_ami" {
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
variable "project_build_version" {
  description = "Build version"
  type        = string
}
variable "asg_launch_version" {
  description = "Auto Scale Group Launch template version"
  type        = string
  default     = "$Latest"
}
variable "yolo5_img_name" {
  description = "Yolo5 image name"
  type        = string
}
variable "max_az_count" {
  description = "Maximum number of AZs to use for subnet creation"
  type        = number
  default     = 2
}
variable "domain_hosted_zone" {
  description = "Main domain hosted zone"
  type        = string
}