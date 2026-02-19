<#
.Synopsis
   Add users to Active Directory security group given an user list
.DESCRIPTION
   This script is to add users to Active Directory security group given an user list
.REQUIREMENTS
   ActiveDirectory Module: https://learn.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2025-ps
.AUTHOR
   Rafael Abel
.DATE
   2026-02-19
#>

Import-Module ActiveDirectory

# Variables
$GroupName = "GroupName"
$LogFile = "C:\Temp\Users_Group_Update_$(Get-Date -Format yyyyMMdd_HHmmss).txt"

# User list (sAMAccountName)
$Users = @(
"username1","username3","username3"
)

# Array
$Added = @()
$NotFound = @()
$Duplicates = @()
$Errors = @()

# Process

foreach ($SamAccount in $Users) {

    $FoundUsers = Get-ADUser -Filter "SamAccountName -eq '$SamAccount'"

    if ($FoundUsers.Count -eq 0) {
        Write-Warning "NOT FOUND: $SamAccount"
        $NotFound += $SamAccount
        continue
    }

    if ($FoundUsers.Count -gt 1) {
        Write-Warning "DUPLICATE: $SamAccount"
        $Duplicates += $SamAccount
        continue
    }

    try {
        Add-ADGroupMember -Identity $GroupName -Members $FoundUsers -ErrorAction Stop
        Write-Host "Added: $SamAccount" -ForegroundColor Green
        $Added += $SamAccount
    }
    catch {
        Write-Warning "ERROR ADDING: $SamAccount"
        $Errors += "$SamAccount - $($_.Exception.Message)"
    }
}

# Log

$LogContent = @()
$LogContent += "Execution Date: $(Get-Date)"
$LogContent += "Group: $GroupName"
$LogContent += "================================================="

$LogContent += "`nUSERS ADDED SUCCESSFULLY:"
if ($Added.Count -eq 0) {
    $LogContent += "None"
} else {
    $LogContent += $Added
}

$LogContent += "`n================================================="
$LogContent += "USERS NOT FOUND:"
if ($NotFound.Count -eq 0) {
    $LogContent += "None"
} else {
    $LogContent += $NotFound
}

$LogContent += "`n================================================="
$LogContent += "DUPLICATE USERS (Multiple AD accounts found):"
if ($Duplicates.Count -eq 0) {
    $LogContent += "None"
} else {
    $LogContent += $Duplicates
}

$LogContent += "`n================================================="
$LogContent += "ERRORS WHILE ADDING TO GROUP:"
if ($Errors.Count -eq 0) {
    $LogContent += "None"
} else {
    $LogContent += $Errors
}

$LogContent | Out-File -FilePath $LogFile -Encoding UTF8

Write-Host "`nProcess completed."
Write-Host "Log file created at: $LogFile"
