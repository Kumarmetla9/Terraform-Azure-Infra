# Output the resource group details
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the created resource group"
  value       = azurerm_resource_group.main.location
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.main.id
}

# Output the virtual network details
output "virtual_network_name" {
  description = "Name of the created virtual network"
  value       = azurerm_virtual_network.main.name
}

output "virtual_network_id" {
  description = "ID of the created virtual network"
  value       = azurerm_virtual_network.main.id
}

output "virtual_network_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

# Subnet outputs
output "subnet_names" {
  description = "Names of all created subnets"
  value       = { for k, v in azurerm_subnet.subnets : k => v.name }
}

output "subnet_ids" {
  description = "IDs of all created subnets"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Address prefixes of all subnets"
  value       = { for k, v in azurerm_subnet.subnets : k => v.address_prefixes }
}

# Individual subnet outputs for easy reference
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = azurerm_subnet.subnets["public"].id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = azurerm_subnet.subnets["private"].id
}

# Network Security Group outputs
output "nsg_ids" {
  description = "IDs of all Network Security Groups"
  value = {
    for tier, nsg in azurerm_network_security_group.nsg : tier => nsg.id
  }
}

output "public_nsg_id" {
  description = "ID of the public Network Security Group"
  value       = azurerm_network_security_group.nsg["public"].id
}

output "private_nsg_id" {
  description = "ID of the private Network Security Group"
  value       = azurerm_network_security_group.nsg["private"].id
}