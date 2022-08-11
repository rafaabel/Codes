<#
.Synopsis
   Retrieve domain users who have not logged on last 180 days
.DESCRIPTION
   Retrieve domain users who have not logged on last 180 days
.REQUIREMENTS
   This script can be run from any domain joined computer
.AUTHOR
   Svidergol, Brian; Allen, Robbie. Active Directory Cookbook: Solutions for Administrators & Developers (Cookbooks (O'Reilly)) (p. 117). O'Reilly Media
.DATE
   03/31/2022
#>

$DaysSince = (Get-Date).AddDays(-180)
Get-ADUser -Filter * -Properties LastLogonDate | Where-Object { ($_.LastLogonDate -le $DaysSince) -and ($_.Enabled -eq $True) -and ($_.LastLogonDate -ne $NULL) } | Select Name, LastLogonDate | Export-Csv "C:\temp\Users_Who_Have_Not_Logged_On_Last_180_Days.csv"
