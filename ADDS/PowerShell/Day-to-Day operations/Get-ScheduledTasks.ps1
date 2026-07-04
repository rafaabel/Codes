<#
.SYNOPSIS
    Exports all scheduled tasks configured on every Domain Controller in the forest.

.DESCRIPTION
    Enumerates every Domain Controller in the forest and queries the root scheduled
    task path on each, collecting task name, state, author, creation date,
    description, and action details. The consolidated inventory is exported to a
    CSV file for auditing scheduled task configuration across the environment.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 05/19/2023
    Requirements : This script must be run from any DC
#>


$Forest = (Get-ADForest).Name
$DCs = Get-ADDomainController -Filter * -Server $Forest | Select-Object -ExpandProperty Name

$results = foreach ($DC in $DCs) {
    Get-ScheduledTask -CimSession $DC -TaskPath "\" -TaskName "*" | Select-Object TaskName, State, Author, Date, Description, @{Name = "DomainController"; Expression = { $DC } } -ExpandProperty Actions 
}

$results | Export-Csv -Path "F:\Temp\ScheduledTasks.csv" -NoTypeInformation