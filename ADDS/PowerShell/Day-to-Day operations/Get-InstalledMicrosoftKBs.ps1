
<#
.SYNOPSIS
    Verifies whether specified Microsoft KB updates are installed on all Domain Controllers.

.DESCRIPTION
    Enumerates every Domain Controller and checks each one's installed hotfixes
    against a defined list of KB numbers, reporting the matching KB IDs and their
    installation dates. Results are exported to a CSV file for patch compliance
    tracking.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 05/11/2022
    Requirements : This script must be run from any DC
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