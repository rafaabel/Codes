<#
.Synopsis
  Script to remove the 'password never expires' flag from the users and change last password set date to current date 
.DESCRIPTION
  Script to remove the 'password never expires' flag from the users and change last password set date to current date
  Also, it grants a grace period of 90 days from the moment the flag is removed 
.REQUIREMENTS
   Check and load Quest ActiveRoles Module if not loaded
   This scrip must be run as Domain Administrator
.AUTHOR
   Walter Porto - walter.porto@effem.com
   Rafael Abel - rafael.abel@effem.com
.DATE
   05/15/2023
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