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
$CsvPath = "C:\Temp\Users.csv"
$LogFile = "C:\Temp\Log_${GroupName}_$(Get-Date -Format yyyyMMdd_HHmmss).txt"

# Import UPN list (CSV without header)
$Users = Get-Content $CsvPath |
    Where-Object { $_.Trim() -ne "" } |
    ForEach-Object { $_.Trim() } |
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
        # Find user via UPN (fast lookup)
        $User = Get-ADUser -Identity $UPN -ErrorAction Stop
    }
    catch {
        Write-Warning "NOT FOUND: $UPN"
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
        Write-Warning "ERROR ADDING: $UPN"
        $Errors += "$UPN - $($_.Exception.Message)"
    }
}

# ---------------- LOG ----------------

$LogContent = @()
$LogContent += "Execution Date: $(Get-Date)"
$LogContent += "Group: $GroupName"
$LogContent += "Total Processed: $($Users.Count)"
$LogContent += "================================================="

$LogContent += "`nUSERS ADDED:"
$LogContent += if ($Added.Count -eq 0) { "None" } else { $Added }

$LogContent += "`n================================================="
$LogContent += "ALREADY MEMBERS:"
$LogContent += if ($AlreadyMember.Count -eq 0) { "None" } else { $AlreadyMember }

$LogContent += "`n================================================="
$LogContent += "USERS NOT FOUND:"
$LogContent += if ($NotFound.Count -eq 0) { "None" } else { $NotFound }

$LogContent += "`n================================================="
$LogContent += "ERRORS:"
$LogContent += if ($Errors.Count -eq 0) { "None" } else { $Errors }

$LogContent | Out-File -FilePath $LogFile -Encoding UTF8

Write-Host "`nProcess completed." -ForegroundColor Cyan
Write-Host "Log file created at: $LogFile"
