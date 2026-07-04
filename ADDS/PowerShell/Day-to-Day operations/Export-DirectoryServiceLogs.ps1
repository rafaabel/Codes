<#
.SYNOPSIS
    Exports the Directory Service Windows event log to a timestamped .evtx file.

.DESCRIPTION
    Creates the C:\LDAP_Performance_Data folder if it does not already exist, then
    uses wevtutil to export the "Directory Service" event log to a timestamped .evtx
    file in that folder. Typically used alongside Enable-LDAPPerformanceMetrics.ps1
    to capture expensive/inefficient LDAP query diagnostics for offline analysis.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 03/19/2025
    Requirements : This script must be run from any DC
                   ref: https://techcommunity.microsoft.com/blog/coreinfrastructureandsecurityblog/how-to-find-expensive-inefficient-and-long-running-ldap-queries-in-active-direct/257859
#>


# Create C:\LDAP_Performance_Data folder if does not exist
if (-not (Test-Path -Path "C:\LDAP_Performance_Data")) {
    New-Item -ItemType Directory -Path "C:\LDAP_Performance_Data" | Out-Null
}
     
# Generate a file name with a timestamp
$outputDir = "C:\LDAP_Performance_Data"
$logName = "Directory Service"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFile = Join-Path -Path $outputDir -ChildPath "$logName`_$timestamp.evtx"
     
# Export the logs
try {
    Write-Host "Exporting '$logName' logs to '$outputFile'..."
    Wevtutil epl "$logName" "$outputFile"
    Write-Host "Export successful!"
}
catch {
    Write-Host "An error occurred: $_"
}
