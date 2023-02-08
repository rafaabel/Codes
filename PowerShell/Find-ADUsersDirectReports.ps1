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
$exportPath = "C:\Temp\file.csv"
$target = "user" #Set the user who you want to get all its direct reports in a recursive way (eg: a president from a segment)
$arrDirectRep = [System.Collections.ArrayList]@(); 
$i = 0;

#Add Members
do {
   $_directreports = Get-QADUser $target -Properties * | Select-Object DirectReports -ExpandProperty DirectReports
   foreach ($object in $_directreports) {
      $arrDirectRep.Add($object);
   }
   $target = $arrDirectRep[$i];
   $i++;
}
while (($_directreports) -or ($i -le $arrDirectRep.Count))

$output = foreach ($user in $arrDirectRep) {
   Get-QADUser $user -Properties * | Select-Object EmployeeID, Name, DisplayName, Mail, extensionAttribute15, physicaldeliveryofficename, extensionAttribute14  
}

$output  | Export-Csv -NoType $exportPath