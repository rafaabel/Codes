<#
.SYNOPSIS
    Exports Active Directory users filtered by site code(s) to a CSV file.

.DESCRIPTION
    Queries Active Directory for all users whose extensionAttribute15 matches one of
    the configured site codes, then exports their distinguished name, display name,
    UPN, mail, enabled status, and site code to a CSV file.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 09/22/2021
    Requirements : This script can be run from any domain joined computer
                   ref: https://www.netwrix.com/how_to_get_all_users_from_a_specific_ou.html
                   ref: https://social.technet.microsoft.com/wiki/contents/articles/32418.active-directory-troubleshooting-server-has-returned-the-following-error-invalid-enumeration-context.aspx
#>


$exportPath = "C:\Temp\file.csv"
$ADObjects = Get-ADUser -Properties * -Filter '
    extensionAttribute15 -eq "SITECODE" -or 
    extensionAttribute15 -eq "SITECODE" -or 
    extensionAttribute15 -eq "SITECODE"'

$ADObjects | Select-Object DistinguishedName, Name, UserPrincipalName, Mail, Enabled, extensionAttribute15 | Export-Csv -NoType $exportPath
