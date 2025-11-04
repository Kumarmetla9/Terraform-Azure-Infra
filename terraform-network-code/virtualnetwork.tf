# Create Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"]]
  }
}

# Create Subnets for different tiers
resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  # Azure Bastion requires a specific subnet name "AzureBastionSubnet"
  name                 = each.key == "bastion" ? "AzureBastionSubnet" : "SUBNET-${upper(each.key)}-${var.project_name}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
}