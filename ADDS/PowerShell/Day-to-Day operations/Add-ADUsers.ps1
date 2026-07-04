<#
.SYNOPSIS
    Bulk-adds users to an Active Directory security group from a CSV list.

.DESCRIPTION
    Reads a list of UPNs from a CSV file and adds each corresponding user to a target
    Active Directory security group. Users already members of the group, users not
    found in AD, and any errors encountered are tracked separately. A detailed log
    file summarizing the run (added, already member, not found, errors) is generated
    at the end of execution.

.NOTES
    Author       : Rafael Abel
    Date         : 2026-02-19
    Requirements : ActiveDirectory Module
                   https://learn.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2025-ps
#>


Import-Module ActiveDirectory

# Variables
$GroupName = "GroupName"
$CsvPath = "C:\Temp\Users.csv"
$LogFile = "C:\Temp\${GroupName} - Log - $(Get-Date -Format yyyyMMdd_HHmmss).txt"

# Import UPN list (CSV without header)
$Users = Get-Content $CsvPath |
    Where-Object { $_.Trim() -ne "" } |
    ForEach-Object { $_.Trim().TrimEnd(',') } |
    Sort-Object -Unique

# Get group once (performance improvement)
$Group = Get-ADGroup -Identity $GroupName -ErrorAction Stop

# Get current group members once (performance improvement)
$CurrentMembers = Get-ADGroupMember -Identity $GroupName -Recursive |
    Select-Object -ExpandProperty DistinguishedName

# Arrays
$Added = @()
$AlreadyMember = @()
$NotFound = @()
$Errors = @()

foreach ($UPN in $Users) {

    try {
       # Search by full UPN
       $User = Get-ADUser -Filter { UserPrincipalName -eq $UPN } -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Not found: $UPN"
        $NotFound += $UPN
        continue
    }

    # Check if already member
    if ($CurrentMembers -contains $User.DistinguishedName) {
        Write-Host "Already member: $UPN" -ForegroundColor Yellow
        $AlreadyMember += $UPN
        continue
    }

    try {
        Add-ADGroupMember -Identity $Group -Members $User -ErrorAction Stop
        Write-Host "Added: $UPN" -ForegroundColor Green
        $Added += $UPN
    }
    catch {
        Write-Warning "Error addding: $UPN"
        $Errors += "$UPN - $($_.Exception.Message)"
    }
}

# ---------------- LOG ----------------

$LogContent = @()
$LogContent += "Execution Date: $(Get-Date)"
$LogContent += "Group: $GroupName"
$LogContent += "Total Processed: $($Users.Count)"
$LogContent += "================================================="

$LogContent += "`nUsers added:"
$LogContent += if ($Added.Count -eq 0) { "None" } else { $Added }

$LogContent += "`n================================================="
$LogContent += "Already members:"
$LogContent += if ($AlreadyMember.Count -eq 0) { "None" } else { $AlreadyMember }

$LogContent += "`n================================================="
$LogContent += "Users not found:"
$LogContent += if ($NotFound.Count -eq 0) { "None" } else { $NotFound }

$LogContent += "`n================================================="
$LogContent += "Errors:"
$LogContent += if ($Errors.Count -eq 0) { "None" } else { $Errors }

$LogContent | Out-File -FilePath $LogFile -Encoding UTF8

Write-Host "`nProcess completed." -ForegroundColor Cyan
Write-Host "Log file created at: $LogFile"
