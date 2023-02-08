<#
.Synopsis
   Search for strings in all GPOs applied to the domain
.DESCRIPTION
   Search for strings in all GPOs applied to the domain
.REQUIREMENTSclear
   This script can be run from any domain joined computer
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
   05/08/2022
#>

# Get the string we want to search for 
$string = Read-Host -Prompt "What string do you want to search for?" 
 
# Set the domain to search for GPOs 
$DomainName = $env:USERDNSDOMAIN 
 
# Find all GPOs in the current domain 
write-host "Finding all the GPOs in $DomainName" 
Import-Module grouppolicy 
$allGposInDomain = Get-GPO -All -Domain $DomainName 
[string[]] $MatchedGPOList = @()

# Look through each GPO's XML for the string 
Write-Host "Starting search...." 
foreach ($gpo in $allGposInDomain) { 
   $report = Get-GPOReport -Guid $gpo.Id -ReportType Xml 
   if ($report -match $string) { 
      write-host "********** Match found in: $($gpo.DisplayName) **********" -foregroundcolor "Green"
      $MatchedGPOList += "$($gpo.DisplayName)";
   } # end if 
   else { 
      Write-Host "No match in: $($gpo.DisplayName)" 
   } # end else 
} # end foreach
Write-Host "`r`n"
Write-Host "Results: **************" -foregroundcolor "Yellow"
foreach ($match in $MatchedGPOList) { 
   Write-Host "Match found in: $($match)" -foregroundcolor "Green"
}