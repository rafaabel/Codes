<#
.Synopsis
    Remove AD users from group
.REQUIREMENTS
    This script must be run from any DC
.AUTHOR
    ref: https://www.alitajran.com/remove-users-from-group-powershell/#:~:text=Users%20PowerShell%20script.-, Bulk%20remove%20users%20from%20group%20with%20CSV%20file, users%20in%20the%20CSV%20file.
.DATE
    02 / 08 / 2023
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