<#
.Synopsis
   Copy group members from one Active Diretory security group to another
.DESCRIPTION
   This script copy group members from one Active Diretory security group to another
.REQUIREMENTS
   ActiveDirectory Module: https://learn.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2025-ps
.AUTHOR
   Rafael Abel
.DATE
   2026-02-12
#>

Import-Module ActiveDirectory

# Source and Target Groups
$SourceGroup = "SourceGroup"
$TargetGroup = "TargetGroup"

try {
    # Get members from source group (users only)
    $SourceMembers = Get-ADGroupMember -Identity $SourceGroup -Recursive |
                     Where-Object { $_.objectClass -eq "user" }

    if (-not $SourceMembers) {
        Write-Host "No user members found in group $SourceGroup" -ForegroundColor Yellow
        return
    }

    # Get current members of target group
    $TargetMembers = Get-ADGroupMember -Identity $TargetGroup -Recursive |
                     Where-Object { $_.objectClass -eq "user" } |
                     Select-Object -ExpandProperty DistinguishedName

    foreach ($User in $SourceMembers) {
        if ($TargetMembers -notcontains $User.DistinguishedName) {
            try {
                Add-ADGroupMember -Identity $TargetGroup -Members $User.DistinguishedName
                Write-Host "Added $($User.SamAccountName) to $TargetGroup" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to add $($User.SamAccountName): $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "$($User.SamAccountName) is already a member of $TargetGroup" -ForegroundColor Cyan
        }
    }
}
catch {
    Write-Host "Error processing groups: $_" -ForegroundColor Red
}
