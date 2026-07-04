<#
.SYNOPSIS
    Exports all Windows services on a computer along with their run-as account.

.DESCRIPTION
    Queries the local Win32_Service WMI class to retrieve every service's name,
    display name, current state, and the account under which it runs (StartName),
    then exports the results to a CSV file.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 09/22/2021
    Requirements : This script can be run from any domain joined computer
#>


Get-CmiObject -Class Win32_Service |
Select-Object Name, DisplayName, State, StartName | 
Export-Csv -NoTypeInformation "C:\Temp\file.csv"