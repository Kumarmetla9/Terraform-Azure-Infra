# Terraform and Provider Configuration

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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  # Optional: Configure backend for state storage
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "terraformstateaccount"
  #   container_name       = "tfstate"
  #   key                  = "vm-infrastructure.terraform.tfstate"
  # }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    # Configure provider features
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
    
    managed_disk {
      expand_without_downtime = true
    }
  }
}

# Random password generation (if needed)
resource "random_password" "vm_passwords" {
  count   = 2 # One for Windows, one for Linux
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Local values for computed configurations
locals {
  common_tags = merge(var.tags, {
    CreatedBy   = "Terraform"
    CreatedDate = timestamp()
  })
  
  # Generate passwords if not provided
  windows_password = var.windows_admin_password != null ? var.windows_admin_password : random_password.vm_passwords[0].result
  linux_password   = var.linux_admin_password != null ? var.linux_admin_password : (var.disable_password_authentication ? null : random_password.vm_passwords[1].result)
}