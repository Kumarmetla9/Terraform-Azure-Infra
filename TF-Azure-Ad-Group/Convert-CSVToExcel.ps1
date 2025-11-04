# PowerShell script to create an Excel template for Azure AD group user management
# Run this script to create a blank Excel template with proper headers

param(
    [string]$ExcelPath = ".\users-template.xlsx"
)

# Check if ImportExcel module is installed
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Host "ImportExcel module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name ImportExcel -Force -AllowClobber -Scope CurrentUser
}

# Import the module
Import-Module ImportExcel

try {
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
    $sampleData | Export-Excel -Path $ExcelPath -WorksheetName "Users" -AutoSize -BoldTopRow -FreezeTopRow
    
    Write-Host "Successfully created Excel template: $ExcelPath" -ForegroundColor Green
    Write-Host "The file contains sample data. Replace it with your actual users." -ForegroundColor Cyan
    Write-Host "Required columns: UserPrincipalName, GroupName" -ForegroundColor Yellow
    Write-Host "Optional columns: FirstName, LastName" -ForegroundColor Yellow
}
catch {
    Write-Host "Error creating Excel template: $($_.Exception.Message)" -ForegroundColor Red
}