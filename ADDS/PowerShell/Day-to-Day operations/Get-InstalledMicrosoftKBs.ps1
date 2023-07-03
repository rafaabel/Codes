
<#
.Synopsis
   Retrieve KB installed in every Domain Controller from forest
.DESCRIPTION
   The script verifies whether a particular update is installed
.REQUIREMENTS
   This script must be run from any DC
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
   05/11/2022
#>

$DCs = Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name
$Patches = "KB5018419" 
$Results = foreach ($DC in $DCs) {
   $HotFixes = Get-HotFix -ComputerName $DC | Where-Object { $_.HotFixID -in $Patches } | Select-Object -Property PSComputerName, HotFixID, InstalledOn
   [PSCustomObject]@{
      DCName      = $DC
      HotFixes    = $HotFixes.HotFixID -join ', '
      InstalledOn = $HotFixes.InstalledOn -join ', '
   }
}
$Results | Export-Csv -Path F:\Temp\DC_Patches.csv -NoTypeInformation