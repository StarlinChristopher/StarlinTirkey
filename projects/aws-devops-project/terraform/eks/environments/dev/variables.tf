variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "aws_profile" {
  type    = string
  default = "aws-dev"
}
variable "vpc_cidr" {
  type    = string
  default = "10.50.0.0/16"
}
variable "cluster_version" {
  type    = string
  default = "1.32"
}
