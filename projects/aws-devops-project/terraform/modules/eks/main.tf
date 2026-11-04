variable "cluster_name" { type = string }
variable "vpc_id" { type = string }
variable "environment" { type = string }

# This module intentionally does not create an EKS cluster yet. Deploying one
# securely requires subnet, IAM, logging, and node-group design, not a placeholder.
output "cluster_name" { value = var.cluster_name }
