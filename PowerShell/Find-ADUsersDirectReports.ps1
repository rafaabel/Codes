<#
.Synopsis
   Script to get all direct reports
.DESCRIPTION
   Script to get all direct reports starting from a specific user in a recursive way
.REQUIREMENTS
   This script can be run from any domain joined computer
.AUTHOR
   Marcos Junior - marcos.junior@effem.com
   Rafael Abel - rafael.abel@effem.com
.DATE
   10/06/2021
#>

#Connection to ARS
Connect-QADService -proxy 

#Variables
$ExportPath = 'C:\Temp\file.csv'
$target = "user" #Set the user who you want to get all its direct reports in a recursive way (eg: a president from a segment)
$ArrDirectRep = [System.Collections.ArrayList]@(); 
$i = 0;

#Add Members
do {
   $_directreports = Get-QADUser $target -Properties * | Select-Object DirectReports -ExpandProperty DirectReports
   foreach ($object in $_directreports) {
      $ArrDirectRep.Add($object);
   }
   $target = $ArrDirectRep[$i];
   $i++;
}
while (($_directreports) -or ($i -le $ArrDirectRep.Count))

$Output = foreach ($user in $ArrDirectRep) {
   Get-QADUser $user -Properties * | Select-Object EmployeeID, Name, DisplayName, Mail, extensionAttribute15, physicaldeliveryofficename, extensionAttribute14  
}

$Output  | Export-Csv -NoType $ExportPath