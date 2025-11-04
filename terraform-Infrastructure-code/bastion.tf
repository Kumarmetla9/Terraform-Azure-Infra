# Bastion Subnet - Create if not using existing network
resource "azurerm_subnet" "bastion_subnet" {
  count                = var.enable_bastion && !var.use_existing_network ? 1 : 0
  name                 = "AzureBastionSubnet"  # Required name for Azure Bastion
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.vnet_name
  address_prefixes     = var.bastion_subnet_address_prefixes
}

# Data source for existing subnet (when using existing subnet like web)
data "azurerm_subnet" "existing_bastion_subnet" {
  count                = var.enable_bastion && var.use_existing_network && var.bastion_subnet_id != null ? 1 : 0
  name                 = split("/", var.bastion_subnet_id)[10]  # Extract subnet name from subnet ID
  virtual_network_name = local.vnet_name
  resource_group_name  = local.resource_group_name
}

# Data source for existing dedicated Bastion subnet (when using dedicated AzureBastionSubnet)
data "azurerm_subnet" "existing_dedicated_bastion_subnet" {
  count                = var.enable_bastion && var.use_existing_network && var.bastion_subnet_id == null ? 1 : 0
  name                 = "AzureBastionSubnet"
  virtual_network_name = local.vnet_name
  resource_group_name  = local.resource_group_name
}

# Use existing or created Bastion subnet
locals {
  bastion_subnet_id = var.enable_bastion ? (
    var.use_existing_network ? (
      var.bastion_subnet_id != null ? var.bastion_subnet_id : data.azurerm_subnet.existing_dedicated_bastion_subnet[0].id
    ) : azurerm_subnet.bastion_subnet[0].id
  ) : null
}

# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion_public_ip" {
  count               = var.enable_bastion ? 1 : 0
  name                = "${var.bastion_name}-pip"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.tags, {
    Service = "Azure Bastion"
    Purpose = "Secure VM Access"
  })
}

# Azure Bastion requires specific NSG rules which should be configured in the existing NSG
data "azurerm_network_security_group" "existing_bastion_nsg" {
  count               = var.enable_bastion && var.bastion_nsg_id != null ? 1 : 0
  name                = var.bastion_nsg_name
  resource_group_name = local.resource_group_name
}

# Local value to determine which NSG to use for Bastion
locals {
  bastion_nsg_id = var.enable_bastion ? (
    var.bastion_nsg_id != null ? var.bastion_nsg_id : 
    (var.bastion_nsg_name != null ? data.azurerm_network_security_group.existing_bastion_nsg[0].id : null)
  ) : null
}


# Azure Bastion Host
resource "azurerm_bastion_host" "main" {
  count               = var.enable_bastion ? 1 : 0
  name                = var.bastion_name
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  sku                 = var.bastion_sku

  # Copy/paste functionality (requires Standard SKU)
  copy_paste_enabled = var.bastion_sku == "Standard" ? var.bastion_copy_paste_enabled : false
  
  # File copy functionality (requires Standard SKU)
  file_copy_enabled = var.bastion_sku == "Standard" ? var.bastion_file_copy_enabled : false
  
  # IP connect functionality (requires Standard SKU) - allows connection via private IP
  ip_connect_enabled = var.bastion_sku == "Standard" ? var.bastion_ip_connect_enabled : false
  
  # Shareable link functionality (requires Standard SKU)
  shareable_link_enabled = var.bastion_sku == "Standard" ? var.bastion_shareable_link_enabled : false
  
  # Tunneling functionality (requires Standard SKU) - enables native client support
  tunneling_enabled = var.bastion_sku == "Standard" ? var.bastion_tunneling_enabled : false

  # IP Configuration
  ip_configuration {
    name                 = "bastion_ip_configuration"
    subnet_id            = local.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip[0].id
  }

  tags = merge(var.tags, {
    Service = "Azure Bastion"
    Purpose = "Secure VM Access"
    SKU     = var.bastion_sku
  })
}

# Diagnostic Settings for Azure Bastion (optional)
resource "azurerm_monitor_diagnostic_setting" "bastion_diagnostics" {
  count                      = var.enable_bastion && var.enable_bastion_diagnostics ? 1 : 0
  name                       = "${var.bastion_name}-diagnostics"
  target_resource_id         = azurerm_bastion_host.main[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Bastion logs
  enabled_log {
    category = "BastionAuditLogs"
  }

  # Bastion metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Local values for Bastion information
locals {
  bastion_info = var.enable_bastion ? {
    bastion_id       = azurerm_bastion_host.main[0].id
    bastion_name     = azurerm_bastion_host.main[0].name
    bastion_fqdn     = azurerm_bastion_host.main[0].dns_name
    bastion_public_ip = azurerm_public_ip.bastion_public_ip[0].ip_address
    bastion_sku      = var.bastion_sku
    connection_methods = {
      azure_portal = "https://portal.azure.com - Navigate to VM and click 'Connect' -> 'Bastion'"
      native_client = var.bastion_sku == "Standard" && var.bastion_tunneling_enabled ? "az network bastion tunnel --name ${var.bastion_name} --resource-group ${local.resource_group_name} --target-resource-id <vm-resource-id> --resource-port <22-or-3389> --port <local-port>" : "Not available (requires Standard SKU with tunneling enabled)"
    }
  } : null
}