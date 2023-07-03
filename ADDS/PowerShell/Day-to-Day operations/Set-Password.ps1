<#
.Synopsis
   Reset passwords
.DESCRIPTION
   Reset passwords given a list of users
.REQUIREMENTS
   This script must be run from any DC
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
   05/18/2023
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