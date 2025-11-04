# West US Environment Variables - Example for different region

# Resource Configuration - Using existing network from west region
resource_group_name = "RG-Platform-company1-west"
location           = "West US 2"
environment        = "west"

# Network Configuration - Import from terraform-network-code (west region)
vnet_name               = "VNET-Platform-company1-west"
vnet_id                 = "/subscriptions/b198900a-d66c-4291-b14a-10b6ed4a76d4/resourceGroups/RG-Platform-company1-west/providers/Microsoft.Network/virtualNetworks/VNET-Platform-company1-west"
vnet_address_space      = ["0.0.0.0/16"]
subnet_name             = "SUBNET-WEB-company1-west"
subnet_id               = "/subscriptions/b198900a-d66c-4291-b14a-10b6ed4a76d4/resourceGroups/RG-Platform-company1-west/providers/Microsoft.Network/virtualNetworks/VNET-Platform-company1-west/subnets/SUBNET-WEB-company1-west"
subnet_address_prefixes = ["0.0.0.0/24"]

# Network Security Group - Using web tier NSG for this example
existing_nsg_id = "/subscriptions/b198900a-d66c-4291-b14a-10b6ed4a76d4/resourceGroups/RG-Platform-company1-west/providers/Microsoft.Network/networkSecurityGroups/NSG-WEB-company1-west"
existing_nsg_name = "NSG-WEB-company1-west"
use_existing_network = true

# Tags - Aligned with west region standards
tags = {
  Environment = "west"
  Project     = "company1-west"
  Owner       = "TG-Mosaic-Cloud Infrastructure"
  CostCenter  = "company1"
  Region      = "WestUS2"
  CreatedBy   = "Terraform"
}

# Windows VM Configuration
windows_vm_name                        = "vm-windows-company1-west"
windows_vm_size                        = "Standard_B4ms"
windows_admin_username                 = "azureadmin"
windows_admin_password                 = "WestRegionPassword123!"
windows_os_disk_storage_account_type   = "StandardSSD_LRS"
windows_image_sku                      = "2022-Datacenter"

# Linux VM Configuration
linux_vm_name                          = "vm-linux-company1-west"
linux_vm_size                          = "Standard_B4ms"
linux_admin_username                   = "azureadmin"
linux_admin_password                   = "WestRegionPassword123!"
disable_password_authentication        = false
linux_os_disk_storage_account_type     = "StandardSSD_LRS"
linux_image_sku                        = "20_04-lts-gen2"

# Security Configuration (Web tier security)
allow_rdp_from_internet = false  # Web tier should still be protected
allow_ssh_from_internet = false  # Web tier should still be protected
allowed_ip_ranges       = ["0.0.0.0/0"]  # Web tier might allow broader access (configure as needed)

# Storage Configuration
create_data_disks                = true
data_disk_size_gb               = 64
data_disk_storage_account_type  = "StandardSSD_LRS"