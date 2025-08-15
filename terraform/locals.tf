locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
    Application = "stylehub"
    Component   = "infrastructure"
  }

  name_prefix = "${var.project_name}-${var.environment}"
}
