<#
.SYNOPSIS
    Exports the membership of one or more Active Directory security groups to CSV.

.DESCRIPTION
    For each group defined in the $groups list, recursively retrieves all user
    members (expanding nested groups), enriches them with display name, email,
    enabled status, department, and title, then exports the resulting membership
    list to an individual CSV file per group under C:\AD_Group_Exports.

.NOTES
    Author       : Rafael Abel
    Date         : 2026-02-18
    Requirements : ActiveDirectory Module
                   https://learn.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2025-ps
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
