# Development Environment Variables

# Resource Configuration - Import from terraform-network-code
resource_group_name = "RG-Platform-dev"  
location           = "eastus"                      
environment        = "dev"

# Network Configuration - Import from terraform-network-code (using database subnet as default)
vnet_name               = "VNET-Platform-dev"                                                                                          # From network terraform output
vnet_address_space      = ["0.0.0.0/16"]                                                                                                   # From network terraform output
subnet_name             = "SUBNET-DB-dev"                                                                                            # From network terraform output (default - database subnet)
subnet_address_prefixes = ["0.0.0.0/24"]                                                                                                   # From network terraform output (default - database subnet)

# Network Security Group - Import from terraform-network-code (using database NSG as default)
existing_nsg_name = "NSG-DB-dev"
use_existing_network = true

# Tier-based Network Mapping (Simplified to public/private subnets)
tier_subnet_mapping = {
  "public"   = ""
  "private"  = ""
}

tier_nsg_mapping = {
  "public"   = ""
  "private"  = ""
}

# Tags - Aligned with network terraform standards
tags = {
  Environment = "dev"
  Project     = "dev"
  Owner       = "Tf-cloud Infrastructure"
  CostCenter  = "DEV"
  CreatedBy   = "Terraform"
}

# Multiple Windows VMs Configuration (with tier-based networking)
windows_vms = {
  "win-sql-ssrs-01" = {
    vm_size                      = "Standard_E2ads_v5"  # 2 vCPU, 32 GB RAM - exact match
    admin_username               = "azureadmin"
    admin_password               = "ChangeMe123!"
    os_disk_storage_account_type = "Premium_LRS"
    
    # SQL Server 2022 Standard Image Configuration
    image_publisher              = "MicrosoftSQLServer"
    image_offer                 = "sql2022-ws2022"
    image_sku                   = "standard-gen2"
    image_version               = "latest"
    os_disk_caching             = "ReadWrite"
    
    # Reserved Instance & Licensing Configuration (1-year reserved)
    license_type                = "Windows_Server"  # Azure Hybrid Benefit for Windows
    
    # Number of data disks to create (1, 2, 3, or 4)
    data_disk_count              = 1
    data_disk_size_gb           = 64      # 64 GB as specified
    data_disk_storage_account_type = "Premium_LRS"
    create_data_disk            = true
    
    tier                         = "private"  # Uses private subnet & NSG
  }
  "win-sql-ssrs-02" = {
    vm_size                      = "Standard_E2ads_v5"  # 2 vCPU, 32 GB RAM - second VM
    admin_username               = "azureadmin"
    admin_password               = "ChangeMe123!"
    os_disk_storage_account_type = "Premium_LRS"
    
    # SQL Server 2022 Standard Image Configuration
    image_publisher              = "MicrosoftSQLServer"
    image_offer                 = "sql2022-ws2022"
    image_sku                   = "standard-gen2"
    image_version               = "latest"
    os_disk_caching             = "ReadWrite"
    
    # Reserved Instance & Licensing Configuration (1-year reserved)
    license_type                = "Windows_Server"  # Azure Hybrid Benefit for Windows
    
    # Number of data disks to create (1, 2, 3, or 4)
    data_disk_count              = 1
    data_disk_size_gb           = 64      # 64 GB as specified
    data_disk_storage_account_type = "Premium_LRS"
    create_data_disk            = true
    
    tier                         = "private"  # Uses private subnet & NSG
  }
}

# Multiple Linux VMs Configuration (with tier-based networking) - COMMENTED OUT
# linux_vms = {
#   "linux-poc-company1-dev" = {
#     vm_size                      = "Standard_B2s"
#     admin_username               = "azureadmin"
#     admin_password               = "ChangeMe123!"
#     disable_password_authentication = false
#     os_disk_storage_account_type = "Premium_LRS"
#     data_disk_count              = 1
#     data_disk_size_gb           = 64
#     data_disk_storage_account_type = "Premium_LRS"
#     
#     tier                         = "private"  # Uses private subnet & NSG
#   }
#   }
# }

# Security Configuration (Bastion-Only Access - Enhanced Security)
allow_rdp_from_internet = false                  
allow_ssh_from_internet = false                  
allowed_ip_ranges       = ["0.0.0.0/26"]     
# Storage Configuration
create_data_disks                = true   
data_disk_size_gb               = 128     
data_disk_storage_account_type  = "Premium_LRS"  

# Azure Bastion Configuration (Enabled in dedicated Bastion subnet with dedicated NSG)
enable_bastion                   = true                                 
bastion_name                     = "bastion-dev"              
bastion_sku                      = "Standard"                         

# Bastion NSG Configuration (Using dedicated Bastion NSG from terraform-network-code)
bastion_nsg_id                   = ""
bastion_nsg_name                 = "NSG-BASTION-dev"

# Bastion Advanced Features (Enabled)
bastion_copy_paste_enabled       = true   
bastion_file_copy_enabled        = true
bastion_ip_connect_enabled       = true
bastion_shareable_link_enabled   = false
bastion_tunneling_enabled        = true

# Azure AD Groups Access Control Configuration
enable_ad_groups                        = true
admin_group_name                       = "dev-admin"    
readonly_group_name                    = "dev-readonly" 
admin_group_role                       = "Contributor"   
readonly_group_role                    = "Reader"        
use_infrastructure_resource_as_target  = "bastion_host"  
