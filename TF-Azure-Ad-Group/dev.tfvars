# Configuration for Azure AD Groups module

# Enable group creation
enable_group_creation = true

# Optional: Set a prefix for all group names (leave empty for no prefix)
group_prefix = ""

# Optional: Set a prefix for mail nicknames (leave empty for no prefix)
mail_prefix = ""

# Define the groups to create
groups = {
  "dev-admin" = {
    name                = "dev-admin"
    description         = "Administrator access group for development environment"
    security_enabled    = true
    mail_enabled        = false
    assignable_to_role  = false
  }
  "dev-readonly" = {
    name                = "dev-readonly"
    description         = "Read-only access group for development environment"
    security_enabled    = true
    mail_enabled        = false
    assignable_to_role  = false
  }
}

# Optional: Specify group owners (object IDs)
# group_owners = ["00000000-0000-0000-0000-000000000000"]

# Optional: Group visibility setting (Private, Public, or Hiddenmembership)
group_visibility = "Private"

# Optional: Whether to prevent duplicate group names
prevent_duplicate_names = true

# Optional: Whether to ignore changes to group members (recommended when using PowerShell)
ignore_member_changes = true
