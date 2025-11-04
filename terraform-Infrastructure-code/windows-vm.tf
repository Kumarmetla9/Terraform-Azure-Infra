# Multiple Windows VMs Configuration

# Create multiple Windows VMs based on the windows_vms variable
# Legacy single VM support: if windows_vms is empty but legacy variables are set, create single VM
locals {
  # Merge legacy single VM config with multiple VMs config
  all_windows_vms = merge(
    var.windows_vms,
    # Add legacy single VM if windows_vms is empty and legacy vm_name is not default and password is provided
    length(var.windows_vms) == 0 && var.windows_vm_name != "vm-windows" && var.windows_admin_password != null ? {
      "${var.windows_vm_name}" = {
        vm_size        = var.windows_vm_size
        admin_username = var.windows_admin_username
        admin_password = var.windows_admin_password
        os_disk_storage_account_type = var.windows_os_disk_storage_account_type
        os_disk_caching = var.windows_os_disk_caching
        image_sku = var.windows_image_sku
        image_publisher = var.windows_image_publisher
        image_offer = var.windows_image_offer
        image_version = var.windows_image_version
        create_data_disk = var.create_data_disks
        data_disk_size_gb = var.data_disk_size_gb
        data_disk_storage_account_type = var.data_disk_storage_account_type
      }
    } : {}
  )
}

# Windows VMs are private - no public IPs (access via Azure Bastion)
# Public IP resources removed for security

# Dynamic NSG and Subnet selection per VM
locals {
  # Default NSG (backward compatibility) - use existing NSG variables
  default_windows_nsg_id = var.use_existing_network && var.existing_nsg_id != null ? var.existing_nsg_id : null
  
  # Default subnet (backward compatibility)
  default_windows_subnet_id = local.subnet_id
  
  # Per-VM NSG selection with priority: VM-specific > tier-based > default
  windows_vm_nsg_mapping = {
    for vm_name, vm_config in local.all_windows_vms :
    vm_name => coalesce(
      vm_config.nsg_id,                                    # 1. VM-specific NSG ID
      lookup(var.tier_nsg_mapping, vm_config.tier, null),  # 2. Tier-based NSG mapping
      local.default_windows_nsg_id                         # 3. Default NSG
    )
  }
  
  # Per-VM subnet selection with priority: VM-specific > tier-based > default
  windows_vm_subnet_mapping = {
    for vm_name, vm_config in local.all_windows_vms :
    vm_name => coalesce(
      vm_config.subnet_id,                                      # 1. VM-specific subnet ID
      lookup(var.tier_subnet_mapping, vm_config.tier, null),   # 2. Tier-based subnet mapping
      local.default_windows_subnet_id                           # 3. Default subnet
    )
  }
}

# Network Interface for Windows VMs
resource "azurerm_network_interface" "windows_vm_nic" {
  for_each            = var.windows_vms
  name                = "${each.key}-nic"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.windows_vm_subnet_mapping[each.key]
    private_ip_address_allocation = "Dynamic"
    # No public IP - VMs are private, accessed via Azure Bastion
  }

  tags = var.tags
}

# Associate Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "windows_vm_nsg_association" {
  for_each                  = var.windows_vms
  network_interface_id      = azurerm_network_interface.windows_vm_nic[each.key].id
  network_security_group_id = local.windows_vm_nsg_mapping[each.key]
}

# Windows Virtual Machines
resource "azurerm_windows_virtual_machine" "main" {
  for_each            = var.windows_vms
  name                = each.key
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  size                = each.value.vm_size
  admin_username      = each.value.admin_username
  admin_password      = each.value.admin_password

  # Disable automatic patching and provision VM agent
  enable_automatic_updates = false
  patch_mode              = "Manual"  # Use Manual patch mode when automatic updates are disabled
  provision_vm_agent       = true

  network_interface_ids = [
    azurerm_network_interface.windows_vm_nic[each.key].id,
  ]

  os_disk {
    caching              = each.value.os_disk_caching
    storage_account_type = each.value.os_disk_storage_account_type
  }

  source_image_reference {
    publisher = each.value.image_publisher
    offer     = each.value.image_offer
    sku       = each.value.image_sku
    version   = each.value.image_version
  }

  tags = var.tags
}

# Data disk for Windows VMs (optional)
resource "azurerm_managed_disk" "windows_vm_data_disk" {
  for_each             = { for k, v in var.windows_vms : k => v if v.create_data_disk }
  name                 = "${each.key}-data-disk"
  location             = local.resource_group_location
  resource_group_name  = local.resource_group_name
  storage_account_type = each.value.data_disk_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = each.value.data_disk_size_gb

  tags = var.tags
}

# Attach data disk to Windows VMs
resource "azurerm_virtual_machine_data_disk_attachment" "windows_vm_data_disk_attachment" {
  for_each           = { for k, v in var.windows_vms : k => v if v.create_data_disk }
  managed_disk_id    = azurerm_managed_disk.windows_vm_data_disk[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.main[each.key].id
  lun                = "10"
  caching            = "ReadWrite"
}

# Custom Script Extension for Windows VMs (optional initialization)
resource "azurerm_virtual_machine_extension" "windows_vm_extension" {
  for_each             = var.windows_vms
  name                 = "${each.key}-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.main[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -Command \"Write-Host 'Windows VM ${each.key} initialized successfully (Size: ${each.value.vm_size})'; Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory\""
  })

  tags = var.tags
}