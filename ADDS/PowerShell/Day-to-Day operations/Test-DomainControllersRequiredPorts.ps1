<#
.Synopsis
   Script to test required ports for DCs
.DESCRIPTION
   Script to test required ports for DCs
.REQUIREMENTS
   This script must be run from any DC
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
   09/27/2021
#>

$destinationdc = "DC"

Test-Netconnection -Computername $destinationdc -Port 3389
Test-Netconnection -Computername $destinationdc -Port 88
Test-Netconnection -Computername $destinationdc -Port 445
Test-Netconnection -Computername $destinationdc -Port 53
Test-Netconnection -Computername $destinationdc -Port 5985
Test-Netconnection -Computername $destinationdc -Port 389
