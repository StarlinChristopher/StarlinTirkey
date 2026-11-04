output "ecr_repository_url" {
  description = "ECR repository URI; push an immutable image tag and use its digest in container_image."
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "load_balancer_dns_name" {
  description = "ALB DNS name. Add a Route 53 alias after choosing a domain."
  value       = aws_lb.app.dns_name
}
