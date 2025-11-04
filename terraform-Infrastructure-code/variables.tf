# Common Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-vm-infrastructure"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "VM-Infrastructure"
    Owner       = "DevOps-Team"
  }
}

# Network Variables
variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "vnet-vm-infrastructure"
}

variable "vnet_id" {
  description = "ID of the existing virtual network (when using existing network)"
  type        = string
  default     = null
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "subnet-vms"
}

variable "subnet_id" {
  description = "ID of the existing subnet (when using existing network)"
  type        = string
  default     = null
}

variable "subnet_address_prefixes" {
  description = "Address prefix for the subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "existing_nsg_id" {
  description = "ID of the existing NSG to use (when using existing network)"
  type        = string
  default     = null
}

variable "existing_nsg_name" {
  description = "Name of the existing NSG to use (when using existing network)"
  type        = string
  default     = null
}

variable "use_existing_network" {
  description = "Whether to use existing network resources instead of creating new ones"
  type        = bool
  default     = false
}

# Tier-based Network Mapping
variable "tier_subnet_mapping" {
  description = "Mapping of tiers to subnet IDs"
  type = map(string)
  default = {}
  # Example:
  # {
  #   "web" = "/subscriptions/.../subnets/SUBNET-WEB-company1-dev"
  #   "app" = "/subscriptions/.../subnets/SUBNET-APP-company1-dev"
  #   "database" = "/subscriptions/.../subnets/SUBNET-DB-company1-dev"
  # }
}

variable "tier_nsg_mapping" {
  description = "Mapping of tiers to NSG IDs"
  type = map(string)
  default = {}
  # Example:
  # {
  #   "web" = "/subscriptions/.../networkSecurityGroups/NSG-WEB-company1-dev"
  #   "app" = "/subscriptions/.../networkSecurityGroups/NSG-APP-company1-dev"
  #   "database" = "/subscriptions/.../networkSecurityGroups/NSG-DB-company1-dev"
  # }
}

# Multiple Windows VMs Configuration
variable "windows_vms" {
  description = "Map of Windows VMs to create with their configurations"
  type = map(object({
    vm_size        = string
    admin_username = string
    admin_password = string
    os_disk_storage_account_type = optional(string, "Premium_LRS")
    os_disk_caching = optional(string, "ReadWrite")
    image_sku = optional(string, "2022-Datacenter")
    image_publisher = optional(string, "MicrosoftWindowsServer")
    image_offer = optional(string, "WindowsServer")
    image_version = optional(string, "latest")
    create_data_disk = optional(bool, false)
    data_disk_size_gb = optional(number, 64)
    data_disk_storage_account_type = optional(string, "Standard_LRS")
    # Network configuration per VM
    subnet_id = optional(string, null)      # Override subnet for this VM
    nsg_id = optional(string, null)         # Override NSG for this VM
    tier = optional(string, "database")     # Tier type: web, app, database
  }))
  default = {}
}

# Legacy single Windows VM Variables (for backward compatibility)
variable "windows_vm_name" {
  description = "Name of the Windows VM (legacy - use windows_vms for multiple VMs)"
  type        = string
  default     = "vm-windows"
}

variable "windows_vm_size" {
  description = "Size of the Windows VM (legacy - use windows_vms for multiple VMs)"
  type        = string
  default     = "Standard_B2s"
}

variable "windows_admin_username" {
  description = "Administrator username for Windows VM (legacy - use windows_vms for multiple VMs)"
  type        = string
  default     = "azureadmin"
}

variable "windows_admin_password" {
  description = "Administrator password for Windows VM (legacy - use windows_vms for multiple VMs)"
  type        = string
  sensitive   = true
  default     = null
}

variable "windows_os_disk_caching" {
  description = "Caching type for Windows VM OS disk"
  type        = string
  default     = "ReadWrite"
}

variable "windows_os_disk_storage_account_type" {
  description = "Storage account type for Windows VM OS disk"
  type        = string
  default     = "Premium_LRS"
}

variable "windows_image_publisher" {
  description = "Publisher of the Windows VM image"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "windows_image_offer" {
  description = "Offer of the Windows VM image"
  type        = string
  default     = "WindowsServer"
}

variable "windows_image_sku" {
  description = "SKU of the Windows VM image"
  type        = string
  default     = "2022-Datacenter"
}

variable "windows_image_version" {
  description = "Version of the Windows VM image"
  type        = string
  default     = "latest"
}

# Multiple Linux VMs Configuration
variable "linux_vms" {
  description = "Map of Linux VMs to create with their configurations"
  type = map(object({
    vm_size        = string
    admin_username = string
    admin_password = optional(string, null)
    disable_password_authentication = optional(bool, false)
    ssh_public_key = optional(string, null)
    os_disk_storage_account_type = optional(string, "Premium_LRS")
    os_disk_caching = optional(string, "ReadWrite")
    image_sku = optional(string, "20_04-lts-gen2")
    image_publisher = optional(string, "Canonical")
    image_offer = optional(string, "0001-com-ubuntu-server-focal")
    image_version = optional(string, "latest")
    create_data_disk = optional(bool, false)
    data_disk_size_gb = optional(number, 64)
    data_disk_storage_account_type = optional(string, "Standard_LRS")
    # Network configuration per VM
    subnet_id = optional(string, null)      # Override subnet for this VM
    nsg_id = optional(string, null)         # Override NSG for this VM
    tier = optional(string, "database")     # Tier type: web, app, database
  }))
  default = {}
}

# Legacy single Linux VM Variables (for backward compatibility)
variable "linux_vm_name" {
  description = "Name of the Linux VM (legacy - use linux_vms for multiple VMs)"
  type        = string
  default     = "vm-linux"
}

variable "linux_vm_size" {
  description = "Size of the Linux VM (legacy - use linux_vms for multiple VMs)"
  type        = string
  default     = "Standard_B2s"
}

variable "linux_admin_username" {
  description = "Administrator username for Linux VM (legacy - use linux_vms for multiple VMs)"
  type        = string
  default     = "azureadmin"
}

variable "linux_admin_password" {
  description = "Administrator password for Linux VM (optional if using SSH keys) (legacy - use linux_vms for multiple VMs)"
  type        = string
  sensitive   = true
  default     = null
}

variable "disable_password_authentication" {
  description = "Disable password authentication for Linux VM (legacy - use linux_vms for multiple VMs)"
  type        = bool
  default     = false
}

variable "linux_ssh_public_key" {
  description = "SSH public key for Linux VM authentication (legacy - use linux_vms for multiple VMs)"
  type        = string
  default     = null
}

variable "linux_os_disk_caching" {
  description = "Caching type for Linux VM OS disk"
  type        = string
  default     = "ReadWrite"
}

variable "linux_os_disk_storage_account_type" {
  description = "Storage account type for Linux VM OS disk"
  type        = string
  default     = "Premium_LRS"
}

variable "linux_image_publisher" {
  description = "Publisher of the Linux VM image"
  type        = string
  default     = "Canonical"
}

variable "linux_image_offer" {
  description = "Offer of the Linux VM image"
  type        = string
  default     = "0001-com-ubuntu-server-focal"
}

variable "linux_image_sku" {
  description = "SKU of the Linux VM image"
  type        = string
  default     = "20_04-lts-gen2"
}

variable "linux_image_version" {
  description = "Version of the Linux VM image"
  type        = string
  default     = "latest"
}

# Security Variables
variable "allow_rdp_from_internet" {
  description = "Allow RDP access from internet to Windows VM"
  type        = bool
  default     = false
}

variable "allow_ssh_from_internet" {
  description = "Allow SSH access from internet to Linux VM"
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access VMs"
  type        = list(string)
  default     = []
}

# Storage Variables
variable "create_data_disks" {
  description = "Whether to create additional data disks for VMs"
  type        = bool
  default     = false
}

variable "data_disk_size_gb" {
  description = "Size of additional data disks in GB"
  type        = number
  default     = 64
}

variable "data_disk_storage_account_type" {
  description = "Storage account type for data disks"
  type        = string
  default     = "Standard_LRS"
}

# Azure Bastion Variables
variable "enable_bastion" {
  description = "Enable Azure Bastion for secure VM access"
  type        = bool
  default     = false
}

variable "bastion_name" {
  description = "Name of the Azure Bastion host"
  type        = string
  default     = "bastion-host"
}

variable "bastion_sku" {
  description = "SKU of Azure Bastion (Basic or Standard)"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard"], var.bastion_sku)
    error_message = "Bastion SKU must be either 'Basic' or 'Standard'."
  }
}

variable "bastion_subnet_address_prefixes" {
  description = "Address prefixes for the AzureBastionSubnet (minimum /26)"
  type        = list(string)
  default     = ["10.0.2.0/26"]
}

variable "bastion_subnet_id" {
  description = "Existing subnet ID to use for Bastion host (alternative to creating dedicated AzureBastionSubnet)"
  type        = string
  default     = null
}

# Bastion NSG Configuration
variable "bastion_nsg_id" {
  description = "ID of the NSG to use for the Bastion subnet"
  type        = string
  default     = null
}

variable "bastion_nsg_name" {
  description = "Name of the NSG to use for the Bastion subnet"
  type        = string
  default     = null
}

# Bastion Standard SKU Features
variable "bastion_copy_paste_enabled" {
  description = "Enable copy/paste functionality (Standard SKU only)"
  type        = bool
  default     = true
}

variable "bastion_file_copy_enabled" {
  description = "Enable file copy functionality (Standard SKU only)"
  type        = bool
  default     = true
}

variable "bastion_ip_connect_enabled" {
  description = "Enable IP connect functionality - connect via private IP (Standard SKU only)"
  type        = bool
  default     = true
}

variable "bastion_shareable_link_enabled" {
  description = "Enable shareable link functionality (Standard SKU only)"
  type        = bool
  default     = false
}

variable "bastion_tunneling_enabled" {
  description = "Enable tunneling functionality for native client support (Standard SKU only)"
  type        = bool
  default     = true
}

# Bastion Diagnostics
variable "enable_bastion_diagnostics" {
  description = "Enable diagnostic settings for Azure Bastion"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Bastion diagnostics"
  type        = string
  default     = null
}

# Azure AD Groups Configuration - References existing groups
# These groups should be created by terraform-ad-groups module first
variable "enable_ad_groups" {
  description = "Enable Azure AD group access control for infrastructure resources (references existing groups)"
  type        = bool
  default     = false
}

variable "admin_group_name" {
  description = "Name of the existing Azure AD admin group (created by terraform-ad-groups module)"
  type        = string
  default     = null
}

variable "readonly_group_name" {
  description = "Name of the existing Azure AD readonly group (created by terraform-ad-groups module)"
  type        = string
  default     = null
}

variable "target_resource_id" {
  description = "Resource ID to assign Azure AD group permissions to (e.g., specific host, resource group). If null, defaults to resource group."
  type        = string
  default     = null
}

variable "use_infrastructure_resource_as_target" {
  description = "Use a specific infrastructure resource as target (e.g., 'bastion_host'). If null, uses resource group."
  type        = string
  default     = null
}

variable "admin_group_role" {
  description = "Role to assign to the admin group"
  type        = string
  default     = "Contributor"
}

variable "readonly_group_role" {
  description = "Role to assign to the readonly group"
  type        = string
  default     = "Reader"
}