# Generic Azure AD Groups Configuration
# This module creates Azure AD groups with flexible configuration options

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Configure the Azure Active Directory Provider
provider "azuread" {
  # Uses the same authentication as azurerm provider
}

# Local values for group configuration
locals {
  # Create groups based on the groups variable
  ad_groups = {
    for group_key, group_config in var.groups : group_key => {
      display_name    = "${var.group_prefix}${group_config.name}"
      description     = group_config.description
      mail_nickname   = "${var.mail_prefix}${lower(replace(group_config.name, " ", "-"))}"
      security_enabled = coalesce(group_config.security_enabled, true)
      mail_enabled    = coalesce(group_config.mail_enabled, false)
      assignable_to_role = coalesce(group_config.assignable_to_role, false)
    }
  }
}

# Data source to get current user (for setting as owner)
data "azuread_client_config" "current" {
  count = var.enable_group_creation ? 1 : 0
}

# Create Azure AD Security Groups
resource "azuread_group" "groups" {
  for_each = var.enable_group_creation ? local.ad_groups : {}

  display_name            = each.value.display_name
  description            = each.value.description
  mail_nickname          = each.value.mail_nickname
  security_enabled       = each.value.security_enabled
  mail_enabled           = each.value.mail_enabled
  assignable_to_role     = each.value.assignable_to_role
  prevent_duplicate_names = var.prevent_duplicate_names

  # Set group owners
  owners = length(var.group_owners) > 0 ? var.group_owners : (
    var.enable_group_creation ? [data.azuread_client_config.current[0].object_id] : []
  )

  # Lifecycle management - ignore member changes since we manage via PowerShell
  lifecycle {
    ignore_changes = [members]
  }

  # Optional: Set group visibility
  visibility = var.group_visibility
}