<#
.SYNOPSIS
    Locates an Active Directory object by its ObjectGUID across every domain in the forest.

.DESCRIPTION
    Iterates through all domains in the current Active Directory forest and searches
    each one for an object matching the specified ObjectGUID, displaying full object
    properties for any match found. Useful when the domain of a known object GUID is
    unknown.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 08/05/2022
    Requirements : This script must be run from any DC
#>


$guid = "OBJECTGUID"

foreach ($dom in (Get-adforest).Domains) { Get-ADObject -filter { ObjectGUID -eq $guid } -Properties * -Server $dom | fl }

