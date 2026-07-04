<#
.SYNOPSIS
    Recursively exports all direct and indirect reports of a given user to a CSV file.

.DESCRIPTION
    Connects to ARS (Active Roles Server) and, starting from a specified target user,
    walks the DirectReports chain recursively to build a full list of all
    subordinates in the reporting hierarchy. Each report's employee ID, name, mail,
    site, office location, and department are then exported to a CSV file.

.NOTES
    Author       : Marcos Junior - marcos.junior@effem.com
                   Rafael Abel - rafael.abel@effem.com
    Date         : 10/06/2021
    Requirements : This script can be run from any domain joined computer
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