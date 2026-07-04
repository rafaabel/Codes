
<#
.SYNOPSIS
    Resets the local machine account password on a list of remote computers.

.DESCRIPTION
    Defines the Reset-ADComputerMachinePassword function, which imports a list of
    computer names from a CSV file and, for each one, remotely invokes
    Reset-ComputerMachinePassword using local and domain administrator credentials.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 05/08/2022
    Requirements : To access the remote machine and run the script, you must have
                   local admin rights and domain admin rights
#>


function Reset-ADComputerMachinePassword {
   [CmdletBinding(SupportsShouldProcess)]
   param()

   $computers = Import-Csv -Path "C:\Temp\file.csv"
   $localCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ".\localuser", (ConvertTo-SecureString -String "password" -AsPlainText -Force) #Get-Credential
   $domainCredential = New-Object System.Management.Automation.PSCredential -ArgumentList 'DOMAIN\domainuser', (ConvertTo-SecureString -String "password" -AsPlainText -Force) #Get-Credential

   foreach ($computer in $computers) {
      Invoke-Command -ComputerName $computer.Name -Credential $using:localCredential -ScriptBlock { Reset-ComputerMachinePassword -Credential $using:domainCredential }
   }
}


