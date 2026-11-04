variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}
variable "environment" { type = string }

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "vpc-${var.environment}", Environment = var.environment }
}

resource "aws_kms_key" "flow_logs" {
  description             = "Encrypt VPC flow logs for ${var.environment}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = { Name = "vpc-flow-logs-${var.environment}", Environment = var.environment }
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/vpc/${var.environment}/flow-logs"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.flow_logs.arn
  tags              = { Environment = var.environment }
}

resource "aws_iam_role" "flow_logs" {
  name_prefix = "vpc-flow-logs-${var.environment}-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "vpc-flow-logs-${var.environment}"
  role = aws_iam_role.flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"]
      Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
    }]
  })
}

resource "aws_flow_log" "main" {
  vpc_id                   = aws_vpc.main.id
  traffic_type             = "REJECT"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs.arn
  iam_role_arn             = aws_iam_role.flow_logs.arn
  max_aggregation_interval = 60
}

output "vpc_id" { value = aws_vpc.main.id }
