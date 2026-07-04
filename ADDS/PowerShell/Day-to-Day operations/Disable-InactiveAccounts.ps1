<#
.SYNOPSIS
    Disables Active Directory accounts listed in a CSV spreadsheet.

.DESCRIPTION
    Imports a CSV file of SamAccountNames and disables each corresponding Active
    Directory user account with Disable-ADAccount, writing a confirmation message
    to the console for every account processed.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 02/16/2022
    Requirements : This script must be run from any DC
#>


$users = Import-Csv -path "C:\Temp\file.csv"

foreach ($user in $users) {
   Disable-ADAccount -Identity $user.SamAccountName
   Write-Host "User $($user) has been disabled"

}