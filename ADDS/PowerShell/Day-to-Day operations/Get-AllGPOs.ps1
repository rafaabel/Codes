<#
.SYNOPSIS
    Searches all Group Policy Objects in the domain for a given text string.

.DESCRIPTION
    Prompts for a search string, retrieves every GPO applied to the current domain,
    and inspects each GPO's XML report for a match. Matching and non-matching GPOs
    are reported to the console as they are processed, followed by a final summary
    of all GPOs where the string was found.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 05/08/2022
    Requirements : This script can be run from any domain joined computer
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