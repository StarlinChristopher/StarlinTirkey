variable "aws_region" {
  type        = string
  description = "AWS region where the ECS service will be deployed."
}

variable "environment" {
  type        = string
  description = "Deployment environment name."
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "Non-overlapping CIDR block for the ECS VPC."
  default     = "10.42.0.0/16"
}

variable "container_image" {
  type        = string
  description = "Immutable ECR image URI, pinned by digest for deployment."
  validation {
    condition     = can(regex("@sha256:[a-f0-9]{64}$", var.container_image))
    error_message = "container_image must be pinned to an immutable sha256 digest."
  }
}

variable "container_port" {
  type        = number
  description = "Application container port."
  default     = 8080
}

variable "task_cpu" {
  type        = number
  description = "Fargate task CPU units."
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "Fargate task memory in MiB."
  default     = 512
}

variable "desired_count" {
  type        = number
  description = "Desired number of ECS tasks."
  default     = 2
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN in this region for the HTTPS ALB listener."
  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:acm:[a-z0-9-]+:[0-9]{12}:certificate/.+$", var.acm_certificate_arn))
    error_message = "Provide an ACM certificate ARN valid in the selected AWS region."
  }
}

variable "alb_ingress_cidrs" {
  type        = list(string)
  description = "Trusted CIDR allowlist for private HTTPS access to the internal ALB."
  default     = []
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable ALB deletion protection for production environments."
  default     = false
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days."
  default     = 30
}

variable "logs_kms_key_arn" {
  type        = string
  description = "Optional customer-managed KMS key ARN for CloudWatch logs."
  default     = null
  nullable    = true
}
