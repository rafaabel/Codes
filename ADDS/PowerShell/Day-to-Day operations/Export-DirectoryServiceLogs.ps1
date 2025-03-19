<#
.Synopsis
   Export Directory Service logs
.DESCRIPTION
   Export Directory Service logs
.REQUIREMENTS
   This script must be run from any DC
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
   ref: https://techcommunity.microsoft.com/blog/coreinfrastructureandsecurityblog/how-to-find-expensive-inefficient-and-long-running-ldap-queries-in-active-direct/257859
.DATE
   03/19/2025
#>

# Create C:\LDAP_Performance_Data folder if does not exist

if (-not (Test-Path -Path "C:\LDAP_Performance_Data")) {

    New-Item -ItemType Directory -Path "C:\LDAP_Performance_Data" | Out-Null

}

# Generate a file name with a timestamp

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$outputFile = Join-Path -Path $outputDir -ChildPath "$logName`_$timestamp.evtx"

# Export the logs

try {

    Write-Host "Exporting '$logName' logs to '$outputFile'..."

    Wevtutil epl "$logName" "$outputFile"

    Write-Host "Export successful!"

} catch {

    Write-Host "An error occurred: $_"

}