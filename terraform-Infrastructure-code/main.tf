# Main configuration file for VM Infrastructure

# Resource Group - Use existing if provided, otherwise create new
data "azurerm_resource_group" "existing" {
  count = var.resource_group_name != null ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "main" {
  count    = var.resource_group_name == null ? 1 : 0
  name     = "rg-vm-infrastructure-${var.environment}"
  location = var.location

  tags = var.tags
}

# Use existing or created resource group
locals {
  resource_group_name = var.resource_group_name != null ? data.azurerm_resource_group.existing[0].name : azurerm_resource_group.main[0].name
  resource_group_location = var.resource_group_name != null ? data.azurerm_resource_group.existing[0].location : azurerm_resource_group.main[0].location
}

# Virtual Network - Use existing if provided, otherwise create new
data "azurerm_virtual_network" "existing" {
  count               = var.vnet_id != null ? 1 : 0
  name                = var.vnet_name
  resource_group_name = local.resource_group_name
}

resource "azurerm_virtual_network" "main" {
  count               = var.vnet_id == null ? 1 : 0
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  tags = var.tags
}

# Use existing or created virtual network
locals {
  vnet_name = var.vnet_id != null ? data.azurerm_virtual_network.existing[0].name : azurerm_virtual_network.main[0].name
  vnet_id   = var.vnet_id != null ? var.vnet_id : azurerm_virtual_network.main[0].id
}

# Subnet - Use existing if provided, otherwise create new
data "azurerm_subnet" "existing" {
  count                = var.subnet_id != null ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = local.vnet_name
  resource_group_name  = local.resource_group_name
}

resource "azurerm_subnet" "main" {
  count                = var.subnet_id == null ? 1 : 0
  name                 = var.subnet_name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.vnet_name
  address_prefixes     = var.subnet_address_prefixes
}

# Use existing or created subnet
locals {
  subnet_id = var.subnet_id != null ? var.subnet_id : azurerm_subnet.main[0].id
}