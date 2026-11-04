terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
locals {
  tags = { Project = "aws-devops-project", Environment = var.environment, ManagedBy = "Terraform", Experience = "guided" }
}
resource "aws_apprunner_auto_scaling_configuration_version" "app" {
  auto_scaling_configuration_name = "aws-devops-${var.environment}"
  max_concurrency                 = var.max_concurrency
  max_size                        = var.max_instances
  min_size                        = var.min_instances
  tags                            = local.tags
}
resource "aws_apprunner_service" "app" {
  service_name                   = "aws-devops-${var.environment}"
  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.app.arn
  source_configuration {
    auto_deployments_enabled = false
    authentication_configuration {
      access_role_arn = var.apprunner_access_role_arn
    }
    image_repository {
      image_identifier      = var.container_image
      image_repository_type = "ECR"
      image_configuration {
        port = tostring(var.container_port)
        runtime_environment_variables = {
          APP_ENV = var.environment
          PORT    = tostring(var.container_port)
        }
      }
    }
  }
  instance_configuration {
    cpu               = var.instance_cpu
    memory            = var.instance_memory
    instance_role_arn = var.instance_role_arn
  }
  health_check_configuration {
    protocol            = "HTTP"
    path                = "/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }
  tags = local.tags
}
output "service_arn" { value = aws_apprunner_service.app.arn }
output "service_url" { value = aws_apprunner_service.app.service_url }
