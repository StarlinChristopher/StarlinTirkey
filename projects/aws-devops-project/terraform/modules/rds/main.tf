variable "db_name" { type = string }
variable "environment" { type = string }

# No database resources are created until subnet, credentials, and encryption
# settings are defined. Never fabricate a production endpoint or password.
output "db_name" { value = var.db_name }
