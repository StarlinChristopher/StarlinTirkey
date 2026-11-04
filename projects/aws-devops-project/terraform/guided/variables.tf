variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "aws_profile" {
  type    = string
  default = "aws-dev"
}
variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}
variable "container_image" {
  type        = string
  description = "ECR image URI with an immutable digest."
  validation {
    condition     = can(regex("@sha256:[a-f0-9]{64}$", var.container_image))
    error_message = "container_image must be pinned by sha256 digest."
  }
}
variable "container_port" {
  type    = number
  default = 8080
}
variable "apprunner_access_role_arn" {
  type = string
}
variable "instance_role_arn" {
  type     = string
  default  = null
  nullable = true
}
variable "instance_cpu" {
  type    = string
  default = "1 vCPU"
}
variable "instance_memory" {
  type    = string
  default = "2 GB"
}
variable "min_instances" {
  type    = number
  default = 1
}
variable "max_instances" {
  type    = number
  default = 5
}
variable "max_concurrency" {
  type    = number
  default = 50
}
