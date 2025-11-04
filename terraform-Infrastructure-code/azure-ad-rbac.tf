# Azure AD Groups Integration for Infrastructure Access Control
# References existing Azure AD groups created by terraform-ad-groups module
#
# Prerequisites:
# 1. Deploy terraform-ad-groups module first to create the Azure AD groups
# 2. Ensure the groups "company1-dev-admin" and "company1-dev-readonly" exist
# 3. Configure the group names in variables to match the created groups
#
# This module only creates role assignments - it does NOT create the AD groups themselves

# Data source to get current client configuration
data "azurerm_client_config" "current" {}

# Data sources to reference existing Azure AD groups created by terraform-ad-groups
data "azuread_group" "admin_group" {
  count        = var.enable_ad_groups && var.admin_group_name != null ? 1 : 0
  display_name = var.admin_group_name
}

data "azuread_group" "readonly_group" {
  count        = var.enable_ad_groups && var.readonly_group_name != null ? 1 : 0
  display_name = var.readonly_group_name
}

# Role assignment for admin group to access bastion host
resource "azurerm_role_assignment" "admin_bastion_access" {
  count                = var.enable_ad_groups && var.admin_group_name != null && var.enable_bastion && var.use_infrastructure_resource_as_target == "bastion_host" ? 1 : 0
  scope                = azurerm_bastion_host.main[0].id
  role_definition_name = var.admin_group_role
  principal_id         = data.azuread_group.admin_group[0].object_id

  depends_on = [azurerm_bastion_host.main, data.azuread_group.admin_group]
}

# Role assignment for readonly group to access bastion host
resource "azurerm_role_assignment" "readonly_bastion_access" {
  count                = var.enable_ad_groups && var.readonly_group_name != null && var.enable_bastion && var.use_infrastructure_resource_as_target == "bastion_host" ? 1 : 0
  scope                = azurerm_bastion_host.main[0].id
  role_definition_name = var.readonly_group_role
  principal_id         = data.azuread_group.readonly_group[0].object_id

  depends_on = [azurerm_bastion_host.main, data.azuread_group.readonly_group]
}

# Role assignment for admin group to access resource group (alternative target)
resource "azurerm_role_assignment" "admin_rg_access" {
  count                = var.enable_ad_groups && var.admin_group_name != null && var.use_infrastructure_resource_as_target == "resource_group" ? 1 : 0
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.resource_group_name}"
  role_definition_name = var.admin_group_role
  principal_id         = data.azuread_group.admin_group[0].object_id

  depends_on = [data.azuread_group.admin_group]
}

# Role assignment for readonly group to access resource group (alternative target)
resource "azurerm_role_assignment" "readonly_rg_access" {
  count                = var.enable_ad_groups && var.readonly_group_name != null && var.use_infrastructure_resource_as_target == "resource_group" ? 1 : 0
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.resource_group_name}"
  role_definition_name = var.readonly_group_role
  principal_id         = data.azuread_group.readonly_group[0].object_id

  depends_on = [data.azuread_group.readonly_group]
}

# Role assignment for admin group to access custom resource
resource "azurerm_role_assignment" "admin_custom_access" {
  count                = var.enable_ad_groups && var.admin_group_name != null && var.target_resource_id != null ? 1 : 0
  scope                = var.target_resource_id
  role_definition_name = var.admin_group_role
  principal_id         = data.azuread_group.admin_group[0].object_id

  depends_on = [data.azuread_group.admin_group]
}

# Role assignment for readonly group to access custom resource
resource "azurerm_role_assignment" "readonly_custom_access" {
  count                = var.enable_ad_groups && var.readonly_group_name != null && var.target_resource_id != null ? 1 : 0
  scope                = var.target_resource_id
  role_definition_name = var.readonly_group_role
  principal_id         = data.azuread_group.readonly_group[0].object_id

  depends_on = [data.azuread_group.readonly_group]
}