
<#
.SYNOPSIS
    Inventories all folders and files on a given drive across every Domain Controller.

.DESCRIPTION
    Enumerates every Domain Controller in the forest and, for each one, recursively
    lists all folders and files found on a specified shared drive letter, exporting
    the consolidated inventory (domain controller, folder path, file name) to a CSV
    file.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 05/22/2023
    Requirements : This script must be run from any DC
#>


$Forest = (Get-ADForest).Name
$DCs = Get-ADDomainController -Filter * -Server $Forest | Select-Object -ExpandProperty Name
$drive = "F"

$results = ForEach ($DC in $DCs) {
    $Folders = Get-ChildItem -Path "\\$DC\$drive$" -Directory -Recurse
    ForEach ($Folder in $Folders) {
        $Files = Get-ChildItem -Path $Folder.FullName -File
        ForEach ($File in $Files) {
            [PSCustomObject]@{
                DomainController = $DC
                Folders          = $Folder.FullName.Replace("\\$DC\F", "")
                Files            = $File.Name
            }
        }
    }
} 

$results | Export-Csv -Path "F:\Temp\AllFoldersAndFiles.csv" -NoTypeInformation