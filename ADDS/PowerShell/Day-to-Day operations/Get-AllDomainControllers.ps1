<#
.SYNOPSIS
    Exports a list of all Domain Controllers across every domain in the forest.

.DESCRIPTION
    Enumerates every domain in the Active Directory forest and retrieves all Domain
    Controllers for each, then exports their name, domain, IPv4 address, and AD site
    to a CSV file.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 09/17/2021
    Requirements : This script must be run from any DC
#>


$AllDCs = (Get-ADForest).Domains | % { Get-ADDomainController -Filter * -Server $_ }
$AllDCs | Select-Object Name, Domain, IPv4Address, Site |  Export-Csv "F:\Temp\file.csv"