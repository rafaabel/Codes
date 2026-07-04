<#
.SYNOPSIS
    Identifies the source of an Active Directory account lockout.

.DESCRIPTION
    Prompts for a username, locates the PDC Emulator for the domain, and queries the
    PDC's Security event log for failed logon events (Event ID 4625) matching the
    user's SID. Matching events are formatted to show the domain controller, event
    ID, lockout timestamp, message, and lockout source (originating computer/IP).

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 02/15/2023
    Requirements : This script must be run from any DC
#>


Import-Module ActiveDirectory
$UserName = Read-Host "Please enter username"
#Get main DC
$PDC = (Get-ADDomainController -Filter * | Where-Object { $_.OperationMasterRoles -contains "PDCEmulator" })
#Get user info
$UserInfo = Get-ADUser -Identity $UserName
#Search PDC for lockout events with ID 4740
$LockedOutEvents = Get-WinEvent -ComputerName $PDC.HostName -FilterHashtable @{LogName = 'Security'; Id = 4625 } -ErrorAction Stop | Sort-Object -Property TimeCreated -Descending
#Parse and filter out lockout events
Foreach ($Event in $LockedOutEvents) {
   If ($Event | Where { $_.Properties[2].value -match $UserInfo.SID.Value }) {

      $Event | Select-Object -Property @(
         @{Label = 'User'; Expression = { $_.Properties[0].Value } }
         @{Label = 'DomainController'; Expression = { $_.MachineName } }
         @{Label = 'EventId'; Expression = { $_.Id } }
         @{Label = 'LockoutTimeStamp'; Expression = { $_.TimeCreated } }
         @{Label = 'Message'; Expression = { $_.Message -split "`r" | Select -First 1 } }
         @{Label = 'LockoutSource'; Expression = { $_.Properties[1].Value } }
      )

   }
}