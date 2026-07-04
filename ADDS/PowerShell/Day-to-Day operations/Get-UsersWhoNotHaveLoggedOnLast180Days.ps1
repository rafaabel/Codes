<#
.SYNOPSIS
    Exports enabled Active Directory users who have not logged on in the last 180 days.

.DESCRIPTION
    Queries all Active Directory user accounts, filtering for those that are enabled,
    have a recorded LastLogonDate, and whose last logon occurred more than 180 days
    ago. Matching users' names and last logon dates are exported to a CSV file for
    inactive account review.

.NOTES
    Author       : Svidergol, Brian; Allen, Robbie. Active Directory Cookbook:
                   Solutions for Administrators & Developers (Cookbooks (O'Reilly))
                   (p. 117). O'Reilly Media
    Date         : 03/31/2022
    Requirements : This script can be run from any domain joined computer
#>


$DaysSince = (Get-Date).AddDays(-180)
Get-ADUser -Filter * -Properties LastLogonDate | Where-Object { ($_.LastLogonDate -le $DaysSince) -and ($_.Enabled -eq $True) -and ($_.LastLogonDate -ne $NULL) } | Select-Object Name, LastLogonDate | Export-Csv "C:\Temp\Users_Who_Have_Not_Logged_On_Last_180_Days.csv"
