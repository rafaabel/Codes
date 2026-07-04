<#
.SYNOPSIS
    Tests network connectivity to a Domain Controller's required ports.

.DESCRIPTION
    Runs Test-NetConnection against a target Domain Controller for the core ports
    required for Active Directory functionality: RDP (3389), Kerberos (88), SMB
    (445), DNS (53), WinRM (5985), and LDAP (389), reporting connectivity results
    for each.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 09/27/2021
    Requirements : This script must be run from any DC
#>


$destinationdc = "DC"

Test-Netconnection -Computername $destinationdc -Port 3389
Test-Netconnection -Computername $destinationdc -Port 88
Test-Netconnection -Computername $destinationdc -Port 445
Test-Netconnection -Computername $destinationdc -Port 53
Test-Netconnection -Computername $destinationdc -Port 5985
Test-Netconnection -Computername $destinationdc -Port 389
