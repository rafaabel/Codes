<#
.Synopsis
   Script to get all users by OU
.DESCRIPTION
   Script to get all users by OU
.REQUIREMENTS
   This script can be run from any domain joined computer
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
   ref: https://www.netwrix.com/how_to_get_all_users_from_a_specific_ou.html
   ref: https://social.technet.microsoft.com/wiki/contents/articles/32418.active-directory-troubleshooting-server-has-returned-the-following-error-invalid-enumeration-context.aspx
.DATE
   09/22/2021
#>

$exportPath = "C:\Temp\file.csv"
$ADObjects = Get-ADUser -Properties * -Filter '
    extensionAttribute15 -eq "SITECODE" -or 
    extensionAttribute15 -eq "SITECODE" -or 
    extensionAttribute15 -eq "SITECODE"'

$ADObjects | Select-Object DistinguishedName, Name, UserPrincipalName, Mail, Enabled, extensionAttribute15 | Export-Csv -NoType $exportPath
