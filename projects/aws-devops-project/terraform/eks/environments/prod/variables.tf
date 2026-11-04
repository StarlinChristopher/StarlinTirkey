variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
variable "aws_profile" {
  type    = string
  default = "aws-prod"
}
variable "vpc_cidr" {
  type    = string
  default = "10.70.0.0/16"
}
variable "cluster_version" {
  type    = string
  default = "1.32"
}
