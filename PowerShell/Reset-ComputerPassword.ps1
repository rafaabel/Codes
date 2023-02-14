
<#
.Synopsis
   Reset computer object password
.DESCRIPTION
   Reset computer object password
.REQUIREMENTS
   To access the remote machine and run the script, you must have the local admin rights and domain admin rights
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
   05/08/2022
#>

function Reset-ADComputerMachinePassword {
   [CmdletBinding(SupportsShouldProcess)]
   param()

   $computers = Import-Csv -Path "C:\file.csv"
   $localCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ".\localuser", (ConvertTo-SecureString -String "password" -AsPlainText -Force) #Get-Credential
   $domainCredential = New-Object System.Management.Automation.PSCredential -ArgumentList 'DOMAIN\domainuser', (ConvertTo-SecureString -String "password" -AsPlainText -Force) #Get-Credential

   foreach ($computer in $computers) {
      Invoke-Command -ComputerName $computer.Name -Credential $using:localCredential -ScriptBlock { Reset-ComputerMachinePassword -Credential $using:domainCredential }
   }
}


