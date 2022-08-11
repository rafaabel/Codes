<#
.Synopsis
   Script to check hardware requirements for Domain Controllers
.DESCRIPTION
   Check hardware requirements according to the pre-defined values
   Technical terms
        RWDC - Read Write Domain Controller
        RODC - Ready Only Domain Controller
        ADDS - Active Directory Domain Services
        DNS - Domain Name System
        OS - Operating System
        VM - Virtual Machine
.REQUIREMENTS
   This script must be run locally from every Windows Server planned to be Domain Controller
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
   03/24/2022
#>

#Declare Global Variables
$C = 139.000000000000
$D = 59.000000000000
$E = 49.000000000000
$F = 199.000000000000
$drives = Get-WmiObject -Class Win32_LogicalDisk -ComputerName localhost | 
Where-Object { $_. DriveType -eq 3 } | 
Select-Object DeviceID, { $_.Size / 1GB }, { $_.FreeSpace / 1GB }

ForEach ($drive in $($drives)) {
    #Check if drive is C and and if its value matches with the drive size requirements:
    If ($drive.DeviceID -eq "C:") {
        If (($($drive. { $_.Size / 1GB }) -ge $C)) {
            Write-Host "$($drive.DeviceID) [Passed]" -ForegroundColor Green
        }
        Else {
            Write-Host "$($drive.DeviceID) [Failed]" -ForegroundColor Red
        }
    }
    #Check if drive is D and if its value matches with the drive size requirements:
    Elseif ($drive.DeviceID -eq "D:") {
        If (($($drive. { $_.Size / 1GB }) -ge $D)) {
            Write-Host "$($drive.DeviceID) [Passed]" -ForegroundColor Green
        }
        Else {
            Write-Host "$($drive.DeviceID) [Failed]" -ForegroundColor Red
        }
    }

    #Check if drive is E and if its value matches with the drive size requirements:
    ElseIf ($drive.DeviceID -eq "E:") {
        If (($($drive. { $_.Size / 1GB }) -ge $E)) {
            Write-Host "$($drive.DeviceID) [Passed]" -ForegroundColor Green
        }
        Else {
            Write-Host "$($drive.DeviceID) [Failed]" -ForegroundColor Red
        }
    }

    #Check if drive is F and if its value matches with the drive size requirements:
    ElseIf ($drives.DeviceID -eq "F:") {
        If (($($drive. { $_.Size / 1GB }) -ge $F)) {
            Write-Host "$($drive.DeviceID) [Passed]" -ForegroundColor Green
        }
        Else {
            Write-Host "$($drive.DeviceID) [Failed]" -ForegroundColor Red
        }
    }
    Else {
        Write-Host "No more drives to be checked" -ForegroundColor Red
    }
}
    
