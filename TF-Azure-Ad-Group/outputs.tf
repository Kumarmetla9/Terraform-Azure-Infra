# Generic Azure AD Groups Outputs

output "group_ids" {
  description = "Map of group keys to their Azure AD group IDs"
  value       = var.enable_group_creation ? { for k, v in azuread_group.groups : k => v.id } : {}
}

output "group_object_ids" {
  description = "Map of group keys to their Azure AD group Object IDs"
  value       = var.enable_group_creation ? { for k, v in azuread_group.groups : k => v.object_id } : {}
}

output "group_display_names" {
  description = "Map of group keys to their display names"
  value       = var.enable_group_creation ? { for k, v in azuread_group.groups : k => v.display_name } : {}
}

output "group_details" {
  description = "Complete details of all created Azure AD groups"
  value = var.enable_group_creation ? {
    for k, v in azuread_group.groups : k => {
      id              = v.id
      object_id       = v.object_id
      display_name    = v.display_name
      description     = v.description
      mail_nickname   = v.mail_nickname
      security_enabled = v.security_enabled
      mail_enabled    = v.mail_enabled
    }
  } : {}
}

# Legacy outputs for backward compatibility (will use the first group if multiple exist)
output "group_id" {
  description = "The ID of the first created Azure AD group (for backward compatibility)"
  value       = var.enable_group_creation && length(azuread_group.groups) > 0 ? values(azuread_group.groups)[0].id : null
}

output "group_object_id" {
  description = "The Object ID of the first created Azure AD group (for backward compatibility)"
  value       = var.enable_group_creation && length(azuread_group.groups) > 0 ? values(azuread_group.groups)[0].object_id : null
}

output "group_display_name" {
  description = "The display name of the first created Azure AD group (for backward compatibility)"
  value       = var.enable_group_creation && length(azuread_group.groups) > 0 ? values(azuread_group.groups)[0].display_name : null
}