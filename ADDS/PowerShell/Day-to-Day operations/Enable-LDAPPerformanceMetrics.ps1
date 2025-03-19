<#
.Synopsis
   Enable LDAP Performance metrics
.DESCRIPTION
   Enable LDAP Performance metrics
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

# Backup the registry to C:\LDAP_Performance_Data

$backupFile = "C:\LDAP_Performance_Data\RegistryBackup_$(Get-Date -Format 'yyyyMMddHHmmss').reg"

reg export HKLM $backupFile

Write-Host "Registry backup created at: $backupFile"

# Function to query registry values

function Get-RegistryValue {

    param (

        [string]$Path,

        [string]$Name

    )

    if (Test-Path "HKLM:\$Path") {

        Get-ItemProperty -Path "HKLM:\$Path" -Name $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $Name

    } else {

        Write-Host "Registry path not found: HKLM:\$Path"

        return $null

    }

}

# Function to set registry values

function Set-RegistryValue {

    param (

        [string]$Path,

        [string]$Name,

        [int]$Value

    )

    if (-not (Test-Path "HKLM:\$Path")) {

        # Create the registry path if it doesn't exist

        New-Item -Path "HKLM:\$Path" -Force | Out-Null

    }

    # Update the desired registry value without overwriting others

    New-ItemProperty -Path "HKLM:\$Path" -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null

}

# Check and set the value for '15 Field Engineering'

$fieldEngPath = "SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics"

$fieldEngKey = "15 Field Engineering"

$currentFieldEngValue = Get-RegistryValue -Path $fieldEngPath -Name $fieldEngKey

Write-Host "Current value of '$fieldEngKey': $currentFieldEngValue"

$changeFieldEng = Read-Host "Would you like to change the value of '$fieldEngKey' to 5? (y/n)"

if ($changeFieldEng -eq "y") {

    Set-RegistryValue -Path $fieldEngPath -Name $fieldEngKey -Value 5

    Write-Host "Updated value of '$fieldEngKey': 5"

}

# Check and inform the user if any specified registry entries do not exist

$filtersPath = "SYSTEM\CurrentControlSet\Services\NTDS\Parameters"

$filtersKeys = @(

    "Expensive Search Results Threshold",

    "Inefficient Search Results Threshold",

    "Search Time Threshold (msecs)"

)

$missingKeys = @()

foreach ($key in $filtersKeys) {

    $currentValue = Get-RegistryValue -Path $filtersPath -Name $key

    if ($currentValue -eq $null) {

        Write-Host "Registry key '$key' does not exist."

        $missingKeys += $key

    } else {

        Write-Host "Current value of '$key': $currentValue"

    }

}



if ($missingKeys.Count -gt 0) {

    Write-Host "The following registry keys do not exist: $($missingKeys -join ', ')"

    $proceed = Read-Host "Would you like to proceed with creating these missing keys? (y/n)"

    if ($proceed -ne "y") {

        Write-Host "Exiting script as per user choice."

        return

    }

}

# Create or update registry values as needed

$filtersValues = @{

    "Expensive Search Results Threshold" = 0

    "Inefficient Search Results Threshold" = 0

    "Search Time Threshold (msecs)" = 100

}

foreach ($key in $filtersValues.Keys) {

    Set-RegistryValue -Path $filtersPath -Name $key -Value $filtersValues[$key]

    Write-Host "Updated value of '$key': $($filtersValues[$key])"

}

Write-Host "Script finished."