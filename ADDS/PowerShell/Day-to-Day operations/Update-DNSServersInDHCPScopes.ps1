<#
.SYNOPSIS
    Validates and updates the DNS Servers (option 006) value across DHCP scopes.

.DESCRIPTION
    Reads a CSV file listing DHCP server names and scope IDs, first displaying the
    current DNS Servers (option 006) value for each scope. A second section then
    reads the desired new DNS server values from the same CSV structure and applies
    them via Set-DhcpServerv4OptionValue (currently running with -WhatIf for safe
    validation before committing changes).

.NOTES
    Author       : Anatoly Ivanitchev - Anatoly.Ivanitchev@effem.com
    Requirements : This script must be run from any DC
#>


#Run below script to validate the DNS servers for all DHCP scopes

# Change the source fine name accordingly (files attached)
$srcfile = "F:\Temp\dhcp-local.csv"  

#To get DHCP 006 DNS Servers option values:
Import-Csv $srcfile | % { 
   $_.serverName + ": " + $_.scopeId
   Get-DhcpServerv4OptionValue -ComputerName $_.serverName -ScopeId $_.scopeId -OptionId 006 
} | format-table scopeId, Value -AutoSize


# Change the source fine name accordingly (files attached)
$srcfile = "F:\Temp\dhcp-local.csv"  

#To set a new 006 DNS Servers DHCP scope option value:
Import-Csv $srcfile | % { 
   $_.serverName + ": " + $_.scopeId
   [string[]]$newoptValue = $_.newoptionValue.Trim().Split(" ")
   $newoptValue
   Set-DhcpServerv4OptionValue -ComputerName $_.serverName -ScopeId $_.scopeId -OptionId 006 -Value $newoptValue -WhatIf
}
