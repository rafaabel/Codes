<#
.Synopsis
    Get all scheduled tasks from forest
.DESCRIPTION
    Get all scheduled tasks from forest
.REQUIREMENTS
    This script must be run from any DC
.AUTHOR
    Rafael Abel - rafael.abel@effem.com
.DATE
    05/19/2023
#>

$Forest = (Get-ADForest).Name
$DCs = Get-ADDomainController -Filter * -Server $Forest | Select-Object -ExpandProperty Name

$results = foreach ($DC in $DCs) {
    Get-ScheduledTask -CimSession $DC -TaskPath "\" -TaskName "*" | Select-Object TaskName, State, Author, Date, Description, @{Name = "DomainController"; Expression = { $DC } } -ExpandProperty Actions 
}

$results | Export-Csv -Path "F:\Temp\ScheduledTasks.csv" -NoTypeInformation