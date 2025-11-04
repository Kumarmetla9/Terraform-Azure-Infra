# Local values for common naming and tagging
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    CostCenter  = var.cost_center
    CreatedBy   = "Terraform"
    CreatedDate = "2025-10-16"  # Static date to prevent tag updates on existing resources
  }

  resource_group_name = "RG-Platform-${var.project_name}"
  vnet_name          = "VNET-Platform-${var.project_name}"
}