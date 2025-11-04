# Generic Azure AD Groups Variables

# Module Control
variable "enable_group_creation" {
  type        = bool
  default     = true
  description = "Whether to create Azure AD groups"
}

# Group Naming Configuration
variable "group_prefix" {
  type        = string
  default     = ""
  description = "Prefix to add to all group names (e.g., 'MyCompany-' or 'Project-')"

  validation {
    condition     = length(var.group_prefix) <= 50
    error_message = "Group prefix must be 50 characters or less."
  }
}

variable "mail_prefix" {
  type        = string
  default     = ""
  description = "Prefix for mail nicknames (used for group email addresses)"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*$", var.mail_prefix))
    error_message = "Mail prefix must contain only alphanumeric characters and hyphens."
  }
}

# Group Management Options
variable "group_owners" {
  type        = list(string)
  default     = []
  description = "List of object IDs to set as owners of all AD groups (if empty, current user will be set as owner)"

  validation {
    condition = alltrue([
      for owner in var.group_owners : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", owner))
    ])
    error_message = "All group owners must be valid Azure AD object IDs (UUIDs)."
  }
}

variable "prevent_duplicate_names" {
  type        = bool
  default     = true
  description = "Whether to prevent creation of groups with duplicate names"
}

variable "ignore_member_changes" {
  type        = bool
  default     = true
  description = "Whether to ignore changes to group members (allows manual member management)"
}

variable "group_visibility" {
  type        = string
  default     = "Private"
  description = "Group visibility setting"

  validation {
    condition     = contains(["Private", "Public", "Hiddenmembership"], var.group_visibility)
    error_message = "Group visibility must be one of: Private, Public, Hiddenmembership."
  }
}

# Dynamic Groups Configuration
variable "groups" {
  type = map(object({
    name                = string
    description         = string
    security_enabled    = optional(bool, true)
    mail_enabled        = optional(bool, false)
    assignable_to_role  = optional(bool, false)
  }))
  default     = {}
  description = <<-EOT
    Map of Azure AD groups to create. Each group can have:
    - name: Display name for the group (will be prefixed with group_prefix)
    - description: Description of the group's purpose
    - security_enabled: Whether this is a security group (default: true)
    - mail_enabled: Whether this is a mail-enabled group (default: false)
    - assignable_to_role: Whether the group can be assigned to Azure AD roles (default: false)
    
    Example:
    {
      "admins" = {
        name        = "Administrators"
        description = "Administrator access group"
        assignable_to_role = true
      }
      "users" = {
        name        = "Users"
        description = "Standard user access group"
      }
    }
  EOT

  validation {
    condition = alltrue([
      for group_key, group in var.groups : length(group.name) >= 1 && length(group.name) <= 200
    ])
    error_message = "All group names must be between 1 and 200 characters."
  }

  validation {
    condition = alltrue([
      for group_key, group in var.groups : length(group.description) <= 1000
    ])
    error_message = "All group descriptions must be 1000 characters or less."
  }
}