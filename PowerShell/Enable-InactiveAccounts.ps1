<#
.Synopsis
   Enable all inactive accounts from spreadsheet
.DESCRIPTION
   Enable all inactive accounts from spreadsheet
.REQUIREMENTS
   This script must be run from any DC
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
   02/14/2022
#>

$users = Import-Csv -path "C:\Temp\file.csv"

foreach ($user in $users) {
   Enable-ADAccount -Identity $user.SamAccountName
   Write-host "User $($user) has been enabled"

}