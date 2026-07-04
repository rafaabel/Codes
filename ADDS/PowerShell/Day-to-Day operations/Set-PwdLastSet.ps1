<#
.SYNOPSIS
    Forces password expiration for a list of users while granting a 90-day grace period.

.DESCRIPTION
    Connects to Active Directory via Quest ActiveRoles, then for each user listed in
    users.txt, removes the "password never expires" flag and resets pwdLastSet
    (first to 0, then to -1) to force the password change policy to re-apply from
    the current date. This effectively grants each user a 90-day grace period from
    the moment the flag is removed before their password is considered expired.

.NOTES
    Author       : Walter Porto - walter.porto@effem.com
                   Rafael Abel - rafael.abel@effem.com
    Date         : 05/15/2023
    Requirements : Quest ActiveRoles Module (loaded automatically if missing)
                   Must be run as Domain Administrator
#>


# Check and load Quest ActiveRoles Module if not loaded

$QADModule = Get-Module ActiveRolesManagementShell

if ($QADModule.Name -ne "ActiveRolesManagementShell") {

   Import-Module ActiveRolesManagementShell
}

# Get Admin Credentials

$cred = Get-Credential -Message "You need domain elevated privileges!"

$PrimaryDC = 'PRIMARYDC'

Clear-Host

Connect-QADService -service $PrimaryDC -Credential $cred

Function forcePasswordExpiration {

   Param(

      [string] $_SamAccountName,

      $cred

   )

   write-host ("User: $_SamAccountName")

   #prepare the grace period

   Get-QADUser $_SamAccountName -Credential $cred | Set-QADUser -ObjectAttributes @{pwdLastSet = '0' } -Credential $cred

   Start-Sleep -s 2

   Get-QADUser $_SamAccountName -Credential $cred | Set-QADUser -ObjectAttributes @{pwdLastSet = '-1' } -Credential $cred

   ######

   Get-QADUser $_SamAccountName -Credential $cred | Set-QADUser -passwordNeverExpires $false -Credential $cred

   Start-Sleep -s 2

}

$users = Get-Content users.txt

foreach ($user in $users) {

   forcePasswordExpiration $user $cred

}