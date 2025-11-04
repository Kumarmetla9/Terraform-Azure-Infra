# Multiple Linux VMs Configuration

# Create multiple Linux VMs based on the linux_vms variable
# Legacy single VM support: if linux_vms is empty but legacy variables are set, create single VM
locals {
  # Merge legacy single VM config with multiple VMs config
  all_linux_vms = merge(
    var.linux_vms,
    # Add legacy single VM if linux_vms is empty and legacy vm_name is not default
    length(var.linux_vms) == 0 && var.linux_vm_name != "vm-linux" ? {
      "${var.linux_vm_name}" = {
        vm_size        = var.linux_vm_size
        admin_username = var.linux_admin_username
        admin_password = var.linux_admin_password
        disable_password_authentication = var.disable_password_authentication
        ssh_public_key = var.linux_ssh_public_key
        os_disk_storage_account_type = var.linux_os_disk_storage_account_type
        os_disk_caching = var.linux_os_disk_caching
        image_sku = var.linux_image_sku
        image_publisher = var.linux_image_publisher
        image_offer = var.linux_image_offer
        image_version = var.linux_image_version
        create_data_disk = var.create_data_disks
        data_disk_size_gb = var.data_disk_size_gb
        data_disk_storage_account_type = var.data_disk_storage_account_type
      }
    } : {}
  )
}

# Linux VMs are private - no public IPs (access via Azure Bastion)
# Public IP resources removed for security

# Dynamic NSG and Subnet selection per VM
locals {
  # Default NSG (backward compatibility) - use existing NSG variables
  default_linux_nsg_id = var.use_existing_network && var.existing_nsg_id != null ? var.existing_nsg_id : null
  
  # Default subnet (backward compatibility)
  default_subnet_id = local.subnet_id
  
  # Per-VM NSG selection with priority: VM-specific > tier-based > default
  vm_nsg_mapping = {
    for vm_name, vm_config in local.all_linux_vms :
    vm_name => coalesce(
      vm_config.nsg_id,                                    # 1. VM-specific NSG ID
      lookup(var.tier_nsg_mapping, vm_config.tier, null),  # 2. Tier-based NSG mapping
      local.default_linux_nsg_id                           # 3. Default NSG
    )
  }
  
  # Per-VM subnet selection with priority: VM-specific > tier-based > default
  vm_subnet_mapping = {
    for vm_name, vm_config in local.all_linux_vms :
    vm_name => coalesce(
      vm_config.subnet_id,                                      # 1. VM-specific subnet ID
      lookup(var.tier_subnet_mapping, vm_config.tier, null),   # 2. Tier-based subnet mapping
      local.default_subnet_id                                   # 3. Default subnet
    )
  }
}

# Network Interface for Linux VMs
resource "azurerm_network_interface" "linux_vm_nic" {
  for_each            = local.all_linux_vms
  name                = "${each.key}-nic"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.vm_subnet_mapping[each.key]
    private_ip_address_allocation = "Dynamic"
    # No public IP - VMs are private, accessed via Azure Bastion
  }

  tags = var.tags
}

# Associate Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "linux_vm_nsg_association" {
  for_each                  = local.all_linux_vms
  network_interface_id      = azurerm_network_interface.linux_vm_nic[each.key].id
  network_security_group_id = local.vm_nsg_mapping[each.key]
}

# Linux Virtual Machines
resource "azurerm_linux_virtual_machine" "main" {
  for_each            = local.all_linux_vms
  name                = each.key
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  size                = each.value.vm_size
  admin_username      = each.value.admin_username

  # Authentication configuration
  disable_password_authentication = each.value.disable_password_authentication
  admin_password                  = each.value.disable_password_authentication ? null : each.value.admin_password

  network_interface_ids = [
    azurerm_network_interface.linux_vm_nic[each.key].id,
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

  # SSH key configuration (if using key-based authentication)
  dynamic "admin_ssh_key" {
    for_each = each.value.ssh_public_key != null ? [1] : []
    content {
      username   = each.value.admin_username
      public_key = each.value.ssh_public_key
    }
  }

  # Boot diagnostics
  boot_diagnostics {
    storage_account_uri = null # Uses managed storage account
  }

  tags = var.tags
}

# Data disk for Linux VMs (optional)
resource "azurerm_managed_disk" "linux_vm_data_disk" {
  for_each             = { for k, v in local.all_linux_vms : k => v if v.create_data_disk }
  name                 = "${each.key}-data-disk"
  location             = local.resource_group_location
  resource_group_name  = local.resource_group_name
  storage_account_type = each.value.data_disk_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = each.value.data_disk_size_gb

  tags = var.tags
}

# Attach data disk to Linux VMs
resource "azurerm_virtual_machine_data_disk_attachment" "linux_vm_data_disk_attachment" {
  for_each           = { for k, v in local.all_linux_vms : k => v if v.create_data_disk }
  managed_disk_id    = azurerm_managed_disk.linux_vm_data_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.main[each.key].id
  lun                = "10"
  caching            = "ReadWrite"
}

# Custom Script Extension for Linux VMs (optional initialization)
resource "azurerm_virtual_machine_extension" "linux_vm_extension" {
  for_each             = local.all_linux_vms
  name                 = "${each.key}-extension"
  virtual_machine_id   = azurerm_linux_virtual_machine.main[each.key].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    "script" = base64encode(<<-EOF
      #!/bin/bash
      echo "Linux VM ${each.key} initialized successfully" > /tmp/vm-init.log
      
      # Install basic utilities (without updating package list)
      apt-get install -y curl wget htop git
      
      # Install Docker (optional)
      # curl -fsSL https://get.docker.com -o get-docker.sh
      # sh get-docker.sh
      # usermod -aG docker ${each.value.admin_username}
      
      # Log system information
      echo "System Information:" >> /tmp/vm-init.log
      echo "VM Name: ${each.key}" >> /tmp/vm-init.log
      echo "VM Size: ${each.value.vm_size}" >> /tmp/vm-init.log
      uname -a >> /tmp/vm-init.log
      df -h >> /tmp/vm-init.log
      free -h >> /tmp/vm-init.log
      
      echo "VM initialization completed at $(date)" >> /tmp/vm-init.log
    EOF
    )
  })

  tags = var.tags
}