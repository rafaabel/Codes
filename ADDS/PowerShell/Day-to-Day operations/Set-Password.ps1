<#
.SYNOPSIS
    Resets Active Directory account passwords for a list of users.

.DESCRIPTION
    Imports a CSV list of SamAccountNames and, for each user, generates a new
    password (via an external password-generation script) and resets the account
    password using Set-ADAccountPassword. Successes and failures are logged both to
    the console and to a log file.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 05/18/2023
    Requirements : This script must be run from any DC
#>

Import-Module ActiveDirectory

$users = Import-Csv -Path "F:\Temp\file.csv"
$logFile = "F:\Temp\password_reset.log"

foreach ($user in $users) {
   $newPassword = C:\Temp\password_generation.ps1
    
   try {
      Set-ADAccountPassword -Identity $user.samaccountname -NewPassword (ConvertTo-SecureString -AsPlainText $newPassword -Force) -Reset
      Write-Host  "$($user.samaccountname) password has been reset" -ForegroundColor Green
      Add-Content $logFile "$($user.samaccountname) password has been reset"

   }
   catch {
      Write-Host  $logFile "$($user.samaccountname) password reset failed with error: $($_.Exception.Message)" -ForegroundColor Red
      Add-Content $logFile "$($user.samaccountname) password reset failed with error: $($_.Exception.Message)"
   }

}