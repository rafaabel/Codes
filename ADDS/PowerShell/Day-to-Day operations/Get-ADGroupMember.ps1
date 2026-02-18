<#
.Synopsis
   Export group members from Active Diretory security group
.DESCRIPTION
   This script export group members from Active Diretory security group
.REQUIREMENTS
   ActiveDirectory Module: https://learn.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2025-ps
.AUTHOR
   Rafael Abel
.DATE
   2026-02-18
#>

# Import Active Directory module
Import-Module ActiveDirectory

# Define groups
$groups = @(
    "Group 1",
    "Group 2",
    "Group 3"
)

# Define export path
$exportPath = "C:\AD_Group_Exports"

# Create folder if it does not exist
if (!(Test-Path $exportPath)) {
    New-Item -Path $exportPath -ItemType Directory
}

foreach ($group in $groups) {

    Write-Host "Processing group: $group" -ForegroundColor Cyan

    # Get group members (recursive to expand nested groups)
    $members = Get-ADGroupMember -Identity $group -Recursive | 
        Where-Object {$_.objectClass -eq "user"} |
        ForEach-Object {
            Get-ADUser $_.SamAccountName -Properties DisplayName, EmailAddress, Enabled, Department, Title
        }

    # Select desired properties
    $exportData = $members | Select-Object `
        Name,
        SamAccountName,
        UserPrincipalName,
        DisplayName,
        EmailAddress,
        Enabled,
        Department,
        Title

    # Create safe filename
    $fileName = ($group -replace "[^a-zA-Z0-9]", "_") + ".csv"
    $fullPath = Join-Path $exportPath $fileName

    # Export to CSV
    $exportData | Export-Csv -Path $fullPath -NoTypeInformation -Encoding UTF8

    Write-Host "Exported to $fullPath" -ForegroundColor Green
}

Write-Host "All groups exported successfully." -ForegroundColor Yellow
