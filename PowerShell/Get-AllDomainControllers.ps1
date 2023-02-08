<#
.Synopsis
   Script to retrieve all domain controllers from domain
.DESCRIPTION
   Script to retrieve all domain controllers from domain
.REQUIREMENTS
   This script must be run from any DC
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
   09/17/2021
#>

$AllDCs = (Get-ADForest).Domains | % { Get-ADDomainController -Filter * -Server $_ }
$AllDCs | Select-Object Name, Domain, IPv4Address, Site |  Export-Csv "C:\Temp\file.csv"