<#
.Synopsis
   Script to retrieve all domain controllers from forest
.DESCRIPTION
   Script to retrieve all domain controllers from forest
.REQUIREMENTS
   This script must be run from any DC
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
   09/17/2021
#>

$AllDCs = (Get-ADForest).Domains | % { Get-ADDomainController -Filter * -Server $_ }
$AllDCs | Select-Object Name, Domain, IPv4Address, Site |  Export-Csv "F:\Temp\file.csv"