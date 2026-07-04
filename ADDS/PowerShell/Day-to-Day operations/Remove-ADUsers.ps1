<#
.SYNOPSIS
    Bulk-removes Active Directory users from a security group based on a CSV list.

.DESCRIPTION
    Imports a list of SamAccountNames from a CSV file and, for each user, checks
    current group membership before removing them from a specified target group.
    Users not found in the source data or not currently members of the target group
    are reported separately. All actions are logged to a transcript file (note: the
    Remove-ADGroupMember call currently runs with -WhatIf for safety and should be
    removed once validated).

.NOTES
    Author       : ref: https://www.alitajran.com/remove-users-from-group-powershell/
    Date         : 02/08/2023
    Requirements : This script must be run from any DC
#>


# Start transcript
Start-Transcript -Path "F:\Temp\Remove-ADUsers.log" -Append

# Import AD Module
Import-Module ActiveDirectory

# Import the data from CSV file and assign it to variable
$Users = Import-Csv "F:\Temp\USB_Permanent exceptions to be disabled.csv"

# Specify target group where the users will be removed from
# You can add the distinguishedName of the group. For example: CN=Pilot,OU=Groups,OU=Company,DC=exoip,DC=local
$Group = "gpo.prod Permanent Exception Block USB storage" 

foreach ($User in $Users) {

    # User from CSV not in AD
    if ($User.samaccountname -eq $null) {
        Write-Host "$($User.samaccountname) does not exist in source file" -ForegroundColor Red
    }
    else {
        # Retrieve AD user group membership
        $ExistingGroups = Get-ADPrincipalGroupMembership $User.samaccountname | Select-Object Name

        # User member of group
        if ($ExistingGroups.Name -eq $Group) {

            # Remove user from group
            Remove-ADGroupMember -Identity $Group -Members $User.samaccountname -Confirm:$false -WhatIf
            Write-Host "Removed $($User.samaccountname) from $Group" -ForeGroundColor Green
        }
        else {
            # User not member of group
            Write-Host "$($User.samaccountname) does not exist in $Group" -ForeGroundColor Yellow
        }
    }
}
Stop-Transcript