<#
.SYNOPSIS
    Copies user members from one Active Directory security group to another.

.DESCRIPTION
    Retrieves all user members (recursively, including nested groups) from a source
    Active Directory security group and adds any that are not already members to a
    target security group. Progress and outcomes (added, already member, or failed)
    are reported to the console for each user processed.

.NOTES
    Author       : Rafael Abel
    Date         : 2026-02-12
    Requirements : ActiveDirectory Module
                   https://learn.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2025-ps
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
