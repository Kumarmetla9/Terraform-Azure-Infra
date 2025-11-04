# Output values for VM Infrastructure

# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_group_name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = local.resource_group_location
}

# Network Outputs
output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = local.vnet_name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = local.vnet_id
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = var.subnet_name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = local.subnet_id
}

# Multiple Windows VMs Outputs
output "windows_vms" {
  description = "Map of Windows VMs with their details"
  value = {
    for k, v in azurerm_windows_virtual_machine.main : k => {
      name           = v.name
      id             = v.id
      size           = v.size
      private_ip     = azurerm_network_interface.windows_vm_nic[k].private_ip_address
      admin_username = v.admin_username
    }
  }
}

output "windows_vm_names" {
  description = "List of Windows VM names"
  value       = [for vm in azurerm_windows_virtual_machine.main : vm.name]
}

output "windows_vm_private_ips" {
  description = "Map of Windows VM names to their private IP addresses"
  value       = { for k, v in azurerm_network_interface.windows_vm_nic : k => v.private_ip_address }
}

# Multiple Linux VMs Outputs
output "linux_vms" {
  description = "Map of Linux VMs with their details"
  value = {
    for k, v in azurerm_linux_virtual_machine.main : k => {
      name           = v.name
      id             = v.id
      size           = v.size
      private_ip     = azurerm_network_interface.linux_vm_nic[k].private_ip_address
      admin_username = v.admin_username
    }
  }
}

output "linux_vm_names" {
  description = "List of Linux VM names"
  value       = [for vm in azurerm_linux_virtual_machine.main : vm.name]
}

output "linux_vm_private_ips" {
  description = "Map of Linux VM names to their private IP addresses"
  value       = { for k, v in azurerm_network_interface.linux_vm_nic : k => v.private_ip_address }
}

# Security Group Information
output "windows_vm_nsg_mapping" {
  description = "Map of Windows VM names to their assigned NSG IDs"
  value       = local.all_windows_vms != null ? { for k, v in local.all_windows_vms : k => local.windows_vm_nsg_mapping[k] } : {}
  sensitive   = true
}

output "linux_vm_nsg_mapping" {
  description = "Map of Linux VM names to their assigned NSG IDs"
  value       = local.all_linux_vms != null ? { for k, v in local.all_linux_vms : k => local.vm_nsg_mapping[k] } : {}
}

# Data Disk Information (if created)
output "windows_vm_data_disks" {
  description = "Map of Windows VM data disk IDs"
  value       = { for k, v in azurerm_managed_disk.windows_vm_data_disk : k => v.id }
}

output "linux_vm_data_disks" {
  description = "Map of Linux VM data disk IDs"
  value       = { for k, v in azurerm_managed_disk.linux_vm_data_disk : k => v.id }
}

# Azure Bastion Information
output "bastion_host_id" {
  description = "ID of the Azure Bastion Host"
  value       = var.enable_bastion ? azurerm_bastion_host.main[0].id : null
}

output "bastion_host_name" {
  description = "Name of the Azure Bastion Host"
  value       = var.enable_bastion ? azurerm_bastion_host.main[0].name : null
}

output "bastion_host_fqdn" {
  description = "Fully Qualified Domain Name of the Azure Bastion Host"
  value       = var.enable_bastion ? azurerm_bastion_host.main[0].dns_name : null
}

output "bastion_public_ip" {
  description = "Public IP address of the Azure Bastion Host"
  value       = var.enable_bastion ? azurerm_public_ip.bastion_public_ip[0].ip_address : null
}

output "bastion_connection_info" {
  description = "Information on how to connect to VMs through Bastion"
  value = var.enable_bastion ? {
    azure_portal_method = "Navigate to Azure Portal -> Virtual Machines -> Select VM -> Connect -> Bastion"
    native_client_method = var.bastion_sku == "Standard" && var.bastion_tunneling_enabled ? {
      description = "Use Azure CLI with native RDP/SSH clients"
      windows_rdp_example = "az network bastion rdp --name ${var.bastion_name} --resource-group ${local.resource_group_name} --target-resource-id <windows-vm-resource-id>"
      linux_ssh_example = "az network bastion ssh --name ${var.bastion_name} --resource-group ${local.resource_group_name} --target-resource-id <linux-vm-resource-id> --auth-type password --username <admin-username>"
    } : {
      description = "Not available (requires Standard SKU with tunneling enabled)"
      windows_rdp_example = null
      linux_ssh_example = null
    }
    bastion_sku = var.bastion_sku
    enabled_features = var.bastion_sku == "Standard" ? [
      var.bastion_copy_paste_enabled ? "Copy/Paste" : null,
      var.bastion_file_copy_enabled ? "File Copy" : null,
      var.bastion_ip_connect_enabled ? "IP Connect" : null,
      var.bastion_shareable_link_enabled ? "Shareable Links" : null,
      var.bastion_tunneling_enabled ? "Native Client Support" : null
    ] : ["Basic Bastion Features"]
  } : null
}

output "bastion_subnet_id" {
  description = "ID of the Azure Bastion subnet"
  value       = var.enable_bastion ? local.bastion_subnet_id : null
}

# Azure AD Groups Access Control
output "ad_groups_access" {
  description = "Azure AD groups configured for infrastructure access"
  value = var.enable_ad_groups ? {
    admin_group = {
      name      = var.admin_group_name
      object_id = length(data.azuread_group.admin_group) > 0 ? data.azuread_group.admin_group[0].object_id : null
      role      = var.admin_group_role
    }
    readonly_group = {
      name      = var.readonly_group_name
      object_id = length(data.azuread_group.readonly_group) > 0 ? data.azuread_group.readonly_group[0].object_id : null
      role      = var.readonly_group_role
    }
    target_type = var.target_resource_id != null ? "custom" : var.use_infrastructure_resource_as_target
    target_resource = var.target_resource_id != null ? var.target_resource_id : (
      var.use_infrastructure_resource_as_target == "bastion_host" && var.enable_bastion ? 
        "bastion_host_configured" : 
        var.use_infrastructure_resource_as_target
    )
  } : null
}

# Summary Output
output "deployment_summary" {
  description = "Summary of the deployed resources"
  sensitive   = true
  value = {
    resource_group = local.resource_group_name
    location       = local.resource_group_location
    environment    = var.environment
    total_vms      = length(local.all_windows_vms) + length(local.all_linux_vms)
    windows_vms_count = length(local.all_windows_vms)
    linux_vms_count   = length(local.all_linux_vms)
    windows_vms = {
      for k, v in azurerm_windows_virtual_machine.main : k => {
        size       = v.size
        private_ip = azurerm_network_interface.windows_vm_nic[k].private_ip_address
      }
    }
    linux_vms = {
      for k, v in azurerm_linux_virtual_machine.main : k => {
        size       = v.size
        private_ip = azurerm_network_interface.linux_vm_nic[k].private_ip_address
      }
    }
    network = {
      vnet_name   = local.vnet_name
      subnet_name = var.subnet_name
      subnet_id   = local.subnet_id
      using_existing_network = var.use_existing_network
    }
    bastion = var.enable_bastion ? {
      name      = azurerm_bastion_host.main[0].name
      fqdn      = azurerm_bastion_host.main[0].dns_name
      public_ip = azurerm_public_ip.bastion_public_ip[0].ip_address
      sku       = var.bastion_sku
    } : null
    ad_groups = var.enable_ad_groups ? {
      enabled = true
      admin_group = var.admin_group_name
      readonly_group = var.readonly_group_name
      target_type = var.target_resource_id != null ? "custom" : var.use_infrastructure_resource_as_target
    } : { enabled = false }
  }
}