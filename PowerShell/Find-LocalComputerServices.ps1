<#
.Synopsis
   Script to get all services running in a computer
.DESCRIPTION
   Script to get all services running in a computer and under which account
.REQUIREMENTS
   This script can be run from any domain joined computer
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
   09/22/2021
#>

Get-CmiObject -Class Win32_Service |
Select-Object Name, DisplayName, State, StartName | 
Export-Csv -NoTypeInformation "C:\Temp\file.csv"