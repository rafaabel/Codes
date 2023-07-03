
<#
.Synopsis
    Get all folders and files in a given drive from forest
.DESCRIPTION
    Get all folders and files in a given drive from forest
.REQUIREMENTS
    This script must be run from any DC
.AUTHOR
    Rafael Abel - rafael.abel@effem.com
.DATE
    05/22/2023
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