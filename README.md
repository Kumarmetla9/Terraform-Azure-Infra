# Azure AD Groups Terraform Module

This Terraform module creates Azure Active Directory (Azure AD) security groups with Excel-based user management via a comprehensive PowerShell script.

## Features

- Create multiple Azure AD security groups
- Configurable group properties (security enabled, mail enabled, role assignable)
- Excel-based user management with a single PowerShell script
- Support for group owners and visibility settings
- Prevention of duplicate group names

## Prerequisites

- Terraform >= 1.0
- Azure CLI or Service Principal with appropriate permissions
- PowerShell 5.1 or later
- Microsoft Graph PowerShell module (auto-installed by script)
- ImportExcel PowerShell module (auto-installed by script)

### Required Azure AD Permissions

- `Group.ReadWrite.All` - To create and manage groups
- `User.Read.All` - To read user information
- `GroupMember.ReadWrite.All` - To manage group membership

## Quick Start

1. **Configure your variables file** (e.g., `1-dev.tfvars`):

```hcl
groups = {
  "dev-admin" = {
    name               = "1-dev-admin"
    description        = "Administrator access group"
    assignable_to_role = false
  }
}
```

2. **Deploy the infrastructure**:

```bash
terraform init
terraform plan -var-file="1-dev.tfvars"
terraform apply -var-file="1-dev.tfvars"
```

3. **Create Excel template and add users**:

```powershell
# Create Excel template
.\Manage-AzureADGroups.ps1 -Action CreateTemplate -ExcelPath ".\users.xlsx"

# Edit the Excel file with your users, then add them to the group
.\Manage-AzureADGroups.ps1 -Action AddUsers -ExcelPath ".\users.xlsx" -GroupName "1-dev-admin"
```

## Configuration

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `groups` | map(object) | `{}` | Map of group configurations |
| `enable_group_creation` | bool | `true` | Whether to create groups |
| `group_prefix` | string | `""` | Prefix for group names |
| `mail_prefix` | string | `""` | Prefix for mail nicknames |
| `group_owners` | list(string) | `[]` | List of group owner object IDs |
| `group_visibility` | string | `"Private"` | Group visibility setting |
| `prevent_duplicate_names` | bool | `true` | Prevent duplicate group names |
| `ignore_member_changes` | bool | `true` | Ignore member changes in Terraform |

### Group Object Properties

```hcl
{
  name                = string      # Display name of the group
  description         = string      # Group description
  security_enabled    = bool        # Whether it's a security group (default: true)
  mail_enabled        = bool        # Whether it's mail-enabled (default: false)
  assignable_to_role  = bool        # Whether group can be assigned to Azure AD roles (default: false)
}
```

## User Management

For adding users to groups, use the consolidated PowerShell script with Excel files:

### Excel File Format

The script creates an Excel template with the following columns:

| Column | Required | Description |
|--------|----------|-------------|
| UserPrincipalName | Yes | User's UPN (email) |
| GroupName | Yes | Name of the group to add user to |
| FirstName | No | User's first name |
| LastName | No | User's last name |

### PowerShell Script Usage

**Create Excel Template:**
```powershell
.\Manage-AzureADGroups.ps1 -Action CreateTemplate -ExcelPath ".\users.xlsx"
```

**Add Users to Group:**
```powershell
# Test run (see what would happen)
.\Manage-AzureADGroups.ps1 -Action AddUsers -ExcelPath ".\users.xlsx" -GroupName "1-dev-admin" -TestRun

# Actual execution
.\Manage-AzureADGroups.ps1 -Action AddUsers -ExcelPath ".\users.xlsx" -GroupName "1-dev-admin"
```

### Example Excel Content:

| UserPrincipalName | GroupName | FirstName | LastName |
|-------------------|-----------|-----------|----------|
| john.doe@.com | 1-dev-admin | John | Doe |
| jane.smith@.com | 1-dev-admin | Jane | Smith |

## Examples

### Single Group

```hcl
groups = {
  "admin" = {
    name               = "my-admin-group"
    description        = "Administrative access group"
    assignable_to_role = false
  }
}
```

### Multiple Groups

```hcl
groups = {
  "dev-admin" = {
    name                = "1-dev-admin"
    description         = "Administrator access group"
    assignable_to_role  = false
  }
  "dev-readonly" = {
    name        = "1-dev-readonly"
    description = "Read-only access group"
    assignable_to_role  = false
  }
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `group_ids` | Map of group names to their object IDs |
| `group_names` | Map of group keys to their display names |
| `created_groups` | Complete group objects |

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure your service principal has the required Graph API permissions
2. **PowerShell Module Missing**: The script automatically installs required modules:
   - Microsoft Graph PowerShell modules
   - ImportExcel module
3. **Excel File Not Found**: Ensure the Excel file path is correct and accessible
4. **User Not Found**: Verify user principal names in Excel file are correct

### PowerShell Script Issues

If the PowerShell script fails:
1. Verify PowerShell execution policy allows script execution
2. Check the Excel file format and content
3. Ensure you have the required Microsoft Graph permissions
4. Use `-TestRun` parameter to verify what would happen before making changes

## Security Considerations

- Use service principals with minimal required permissions
- Store sensitive configuration in Azure Key Vault
- Regularly review group memberships
- Enable audit logging for group changes
- Use `assignable_to_role = false` unless specifically needed for role assignments

## License

This module is provided as-is for educational and development purposes.


Network Code:
# Azure Resource Group Terraform Configuration

This Terraform configuration creates an Azure Resource Group with enterprise-standard naming conventions, tagging, and configuration management.

## Project Structure

```
terraform/
├── provider.tf      # Azure provider configuration
├── main.tf         # Resource definitions (Resource Group)
├── variables.tf    # Variable definitions
├── dev.tfvars      # Development environment variables
├── prod.tfvars     # Production environment variables
└── README.md       # This file
```

## Features

- **Enterprise Naming Convention**: Resources follow the pattern `{project}-{environment}-{resource_type}`
- **Comprehensive Tagging**: All resources are tagged with Environment, Project, Owner, Cost Center, Creation info
- **Environment-specific Configuration**: Separate variable files for dev and prod environments
- **Input Validation**: Variables include validation rules for data integrity
- **Lifecycle Management**: Prevents unintended changes to creation timestamps

## Prerequisites

1. **Azure CLI**: Install and authenticate with Azure
   ```bash
   az login
   ```

2. **Terraform**: Install Terraform (>= 1.0)
   ```bash
   terraform --version
   ```

## Usage

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Plan Deployment
For development environment:
```bash
terraform plan -var-file="dev.tfvars"
```

For production environment:
```bash
terraform plan -var-file="prod.tfvars"
```

### 3. Apply Configuration
For development environment:
```bash
terraform apply -var-file="dev.tfvars"
```

For production environment:
```bash
terraform apply -var-file="prod.tfvars"
```

### 4. Destroy Resources (when needed)
```bash
terraform destroy -var-file="dev.tfvars"
```

## Configuration

### Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `environment` | Environment name (dev, test, staging, prod) | string | - | Yes |
| `project_name` | Project name (lowercase, alphanumeric, hyphens) | string | - | Yes |
| `location` | Azure region | string | "East US" | No |
| `owner` | Resource owner | string | - | Yes |
| `cost_center` | Cost center for billing | string | - | Yes |

### Environment Files

- **dev.tfvars**: Development environment settings
- **prod.tfvars**: Production environment settings

Customize these files with your specific values before deployment.

## Outputs

The configuration provides the following outputs:
- `resource_group_name`: Name of the created resource group
- `resource_group_location`: Location of the resource group
- `resource_group_id`: Azure resource ID

## Security Considerations

- Uses Azure CLI authentication by default
- Resource group deletion protection can be configured
- All variables are validated for proper format
- Sensitive variables are marked appropriately

## Customization

To customize for your organization:

1. Update the `project_name` in the `.tfvars` files
2. Modify the `location` to your preferred Azure region
3. Update tagging values (`owner`, `cost_center`) as needed
4. Add additional resources to `main.tf` as required

## Best Practices Implemented

- ✅ Consistent naming conventions
- ✅ Comprehensive resource tagging
- ✅ Input validation
- ✅ Environment-specific configurations
- ✅ State management ready (backend configuration available)
- ✅ Lifecycle management
- ✅ Output values for integration

## Troubleshooting

### Common Issues

1. **Authentication Error**: Ensure you're logged in to Azure CLI
   ```bash
   az account show
   ```

2. **Permission Error**: Verify your Azure account has sufficient permissions to create resource groups

3. **Validation Error**: Check that all required variables are provided in your `.tfvars` file

4. **Region Availability**: Ensure the specified Azure region supports the resources you want to create

## Next Steps

After creating the resource group, you can extend this configuration to include:
- Storage accounts
- Virtual networks
- Key vaults
- Other Azure resources

Simply add the resource definitions to `main.tf` and corresponding variables to `variables.tf`.
