<#
.SYNOPSIS
    Comprehensive Azure AD Group management script using Microsoft Graph and Excel files.

.DESCRIPTION
    This script provides functionality to:
    1. Create Excel templates for user data
    2. Add users to Azure AD groups from Excel files
    Uses Microsoft Graph PowerShell SDK and Excel files exclusively.

.PARAMETER Action
    The action to perform: 'CreateTemplate' or 'AddUsers'

.PARAMETER ExcelPath
    Path to the Excel file (input for AddUsers, output for CreateTemplate)

.PARAMETER GroupName
    Name of the Azure AD group to add users to (required for AddUsers action)

.PARAMETER TestRun
    Shows what would be done without actually making changes (for AddUsers action)

.EXAMPLE
    .\Manage-AzureADGroups.ps1 -Action CreateTemplate -ExcelPath ".\users-template.xlsx"
    
.EXAMPLE
    .\Manage-AzureADGroups.ps1 -Action AddUsers -ExcelPath ".\users-template.xlsx" -GroupName "caremore-dev-admin"
    
.EXAMPLE
    .\Manage-AzureADGroups.ps1 -Action AddUsers -ExcelPath ".\users-template.xlsx" -GroupName "caremore-dev-admin" -TestRun
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("CreateTemplate", "AddUsers")]
    [string]$Action,
    
    [Parameter(Mandatory = $true)]
    [string]$ExcelPath,
    
    [Parameter(Mandatory = $false)]
    [string]$GroupName,
    
    [Parameter(Mandatory = $false)]
    [switch]$TestRun
)

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check and install required modules
function Install-RequiredModules {
    param([bool]$IncludeGraph = $false)
    
    $modules = @("ImportExcel")
    
    if ($IncludeGraph) {
        $modules += @("Microsoft.Graph.Authentication", "Microsoft.Graph.Groups", "Microsoft.Graph.Users")
    }
    
    foreach ($module in $modules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-ColorOutput "Installing module: $module" "Yellow"
            Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
        }
    }
}

# Function to create Excel template
function New-ExcelTemplate {
    param([string]$Path)
    
    try {
        Write-ColorOutput "Creating Excel template at: $Path" "Cyan"
        
        # Install ImportExcel module
        Install-RequiredModules -IncludeGraph $false
        Import-Module ImportExcel -Force
        
        # Create sample data with proper headers
        $sampleData = @(
            [PSCustomObject]@{
                UserPrincipalName = "john.doe@company.com"
                GroupName = "caremore-dev-admin"
                FirstName = "John"
                LastName = "Doe"
            },
            [PSCustomObject]@{
                UserPrincipalName = "jane.smith@company.com"
                GroupName = "caremore-dev-admin"
                FirstName = "Jane"
                LastName = "Smith"
            }
        )
        
        # Export to Excel with formatting
        $sampleData | Export-Excel -Path $Path -WorksheetName "Users" -AutoSize -BoldTopRow -FreezeTopRow
        
        Write-ColorOutput "Successfully created Excel template: $Path" "Green"
        Write-ColorOutput "The file contains sample data. Replace it with your actual users." "Cyan"
        Write-ColorOutput "Required columns: UserPrincipalName, GroupName" "Yellow"
        Write-ColorOutput "Optional columns: FirstName, LastName" "Yellow"
        
        return $true
    }
    catch {
        Write-ColorOutput "Error creating Excel template: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to connect to Microsoft Graph
function Connect-ToMicrosoftGraph {
    try {
        Write-ColorOutput "Checking Microsoft Graph connection..." "Cyan"
        
        # Install required modules
        Install-RequiredModules -IncludeGraph $true
        
        # Import required modules
        Import-Module Microsoft.Graph.Users -Force
        Import-Module Microsoft.Graph.Groups -Force
        
        # Check if already connected
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if ($null -eq $context) {
            Write-ColorOutput "Connecting to Microsoft Graph..." "Cyan"
            Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All" -NoWelcome
            Write-ColorOutput "Successfully connected to Microsoft Graph" "Green"
        } else {
            Write-ColorOutput "Already connected to Microsoft Graph as: $($context.Account)" "Green"
        }
        return $true
    }
    catch {
        Write-ColorOutput "Failed to connect to Microsoft Graph: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to get Azure AD group by name
function Get-AzureADGroupByName {
    param([string]$Name)
    
    try {
        $group = Get-MgGroup -Filter "displayName eq '$Name'" -ErrorAction Stop
        if ($null -eq $group -or $group.Count -eq 0) {
            Write-ColorOutput "Group '$Name' not found in Azure AD" "Red"
            return $null
        }
        Write-ColorOutput "Found group: $($group.DisplayName) (Id: $($group.Id))" "Green"
        return $group
    }
    catch {
        Write-ColorOutput "Error finding group '$Name': $($_.Exception.Message)" "Red"
        return $null
    }
}

# Function to get user by UPN
function Get-AzureADUserByUPN {
    param([string]$UserPrincipalName)
    
    try {
        $user = Get-MgUser -UserId $UserPrincipalName -ErrorAction Stop
        return $user
    }
    catch {
        Write-ColorOutput "User '$UserPrincipalName' not found in Azure AD: $($_.Exception.Message)" "Yellow"
        return $null
    }
}

# Function to check if user is already a member of the group
function Test-GroupMembership {
    param(
        [string]$GroupId,
        [string]$UserId
    )
    
    try {
        $member = Get-MgGroupMember -GroupId $GroupId -Filter "id eq '$UserId'" -ErrorAction SilentlyContinue
        return ($null -ne $member -and $member.Count -gt 0)
    }
    catch {
        Write-ColorOutput "Error checking group membership: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to add user to group
function Add-UserToAzureADGroup {
    param(
        [object]$Group,
        [object]$User,
        [switch]$TestRun
    )
    
    $isAlreadyMember = Test-GroupMembership -GroupId $Group.Id -UserId $User.Id
    
    if ($isAlreadyMember) {
        Write-ColorOutput "  User '$($User.UserPrincipalName)' is already a member of group '$($Group.DisplayName)'" "Yellow"
        return $true
    }
    
    if ($TestRun) {
        Write-ColorOutput "  TESTRUN: Would add user '$($User.UserPrincipalName)' to group '$($Group.DisplayName)'" "Cyan"
        return $true
    }
    
    try {
        New-MgGroupMember -GroupId $Group.Id -DirectoryObjectId $User.Id
        Write-ColorOutput "  Successfully added user '$($User.UserPrincipalName)' to group '$($Group.DisplayName)'" "Green"
        return $true
    }
    catch {
        Write-ColorOutput "  Failed to add user '$($User.UserPrincipalName)' to group '$($Group.DisplayName)': $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to add users from Excel file
function Add-UsersFromExcel {
    param(
        [string]$ExcelPath,
        [string]$GroupName,
        [switch]$TestRun
    )
    
    try {
        Write-ColorOutput "=== Adding Users to Azure AD Group from Excel ===" "Magenta"
        Write-ColorOutput "Starting execution at $(Get-Date)" "Cyan"
        
        # Check if Excel file exists
        if (-not (Test-Path $ExcelPath)) {
            Write-ColorOutput "Excel file not found: $ExcelPath" "Red"
            return $false
        }
        
        # Connect to Microsoft Graph
        if (-not (Connect-ToMicrosoftGraph)) {
            return $false
        }
        
        # Read Excel file
        Write-ColorOutput "Reading Excel file: $ExcelPath" "Cyan"
        Import-Module ImportExcel -Force
        $userData = Import-Excel -Path $ExcelPath -WorksheetName "Users"
        
        # Validate Excel structure
        if ($userData.Count -eq 0) {
            Write-ColorOutput "Excel file is empty" "Red"
            return $false
        }
        
        # Get the group
        Write-ColorOutput "Looking up group: $GroupName" "Cyan"
        $group = Get-AzureADGroupByName -Name $GroupName
        if ($null -eq $group) {
            return $false
        }
        
        # Process each user
        $successCount = 0
        $failureCount = 0
        $skippedCount = 0
        
        Write-ColorOutput "`nProcessing $($userData.Count) users..." "Cyan"
        
        foreach ($userRow in $userData) {
            $userUPN = $userRow.UserPrincipalName
            if ([string]::IsNullOrWhiteSpace($userUPN)) {
                $userUPN = $userRow.'User Principal Name'  # Try alternative column name
            }
            
            if ([string]::IsNullOrWhiteSpace($userUPN)) {
                Write-ColorOutput "Skipping row with empty UserPrincipalName" "Yellow"
                $skippedCount++
                continue
            }
            
            $userUPN = $userUPN.Trim()
            Write-ColorOutput "`nProcessing user: $userUPN -> Group: $GroupName" "White"
            
            # Get the user
            $user = Get-AzureADUserByUPN -UserPrincipalName $userUPN
            if ($null -eq $user) {
                $failureCount++
                continue
            }
            
            # Add user to group
            if (Add-UserToAzureADGroup -Group $group -User $user -TestRun:$TestRun) {
                $successCount++
            } else {
                $failureCount++
            }
        }
        
        # Summary
        Write-ColorOutput "`n=== Execution Summary ===" "Magenta"
        Write-ColorOutput "Total users processed: $($userData.Count)" "Cyan"
        Write-ColorOutput "Successful operations: $successCount" "Green"
        Write-ColorOutput "Failed operations: $failureCount" "Red"
        Write-ColorOutput "Skipped operations: $skippedCount" "Yellow"
        Write-ColorOutput "Completed at $(Get-Date)" "Cyan"
        
        return ($failureCount -eq 0)
    }
    catch {
        Write-ColorOutput "Script execution failed: $($_.Exception.Message)" "Red"
        Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" "Red"
        return $false
    }
}

# Main execution logic
try {
    Write-ColorOutput "=== Azure AD Group Management Script ===" "Magenta"
    Write-ColorOutput "Action: $Action" "Cyan"
    
    switch ($Action) {
        "CreateTemplate" {
            if (-not (New-ExcelTemplate -Path $ExcelPath)) {
                exit 1
            }
        }
        "AddUsers" {
            if ([string]::IsNullOrWhiteSpace($GroupName)) {
                Write-ColorOutput "GroupName parameter is required for AddUsers action" "Red"
                exit 1
            }
            if (-not (Add-UsersFromExcel -ExcelPath $ExcelPath -GroupName $GroupName -TestRun:$TestRun)) {
                exit 1
            }
        }
    }
    
    Write-ColorOutput "`nScript completed successfully!" "Green"
}
catch {
    Write-ColorOutput "Script failed: $($_.Exception.Message)" "Red"
    exit 1
}