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
  name = "aws-devops-staging"
  tags = { Project = "aws-devops-project", Environment = "staging", ManagedBy = "Terraform" }
}
module "network" {
  source                  = "../../modules/network"
  name                    = local.name
  vpc_cidr                = var.vpc_cidr
  availability_zone_count = 3
  nat_gateway_count       = 3
  tags                    = local.tags
}
module "cluster" {
  source              = "../../modules/cluster"
  cluster_name        = local.name
  cluster_version     = var.cluster_version
  private_subnet_ids  = module.network.private_subnet_ids
  node_instance_types = ["t3.large"]
  node_desired_size   = 2
  node_min_size       = 2
  node_max_size       = 6
  tags                = local.tags
}
output "cluster_arn" { value = module.cluster.cluster_arn }
output "cluster_name" { value = module.cluster.cluster_name }
output "vpc_id" { value = module.network.vpc_id }
output "private_subnet_ids" { value = module.network.private_subnet_ids }
output "cluster_log_group_name" { value = module.cluster.cluster_log_group_name }
