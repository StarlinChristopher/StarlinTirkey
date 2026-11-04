variable "name" { type = string }
variable "vpc_cidr" { type = string }
variable "availability_zone_count" { type = number }
variable "nat_gateway_count" {
  type        = number
  description = "One for economical dev, or one per AZ for stage/prod resilience."
}
variable "tags" { type = map(string) }
