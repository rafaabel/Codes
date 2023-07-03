<#
.Synopsis
   Get domain objects by ID from forest
.DESCRIPTION
   Get domain objects by ID from forest
.REQUIREMENTS
   This script must be run from any DC
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
   08/05/2022
#>

$guid = "OBJECTGUID"

foreach ($dom in (Get-adforest).Domains) { Get-ADObject -filter { ObjectGUID -eq $guid } -Properties * -Server $dom | fl }

