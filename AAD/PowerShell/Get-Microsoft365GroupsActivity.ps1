<#
.SYNOPSIS
    Downloads the Microsoft 365 Groups activity report from Microsoft Graph.

.DESCRIPTION
    Connects to Microsoft Graph and calls the getOffice365GroupsActivityDetail reporting
    endpoint for the last 180 days, saving the raw report directly to
    Microsoft365GroupsActivity.csv. The exported data can be used for governance reviews,
    identifying stale groups, and general Microsoft 365 group activity auditing.

.NOTES
    Author       : Rafael Abel - rgonca10@ext.uber.com
    Date         : 2025-09-17
    Requirements : Microsoft Graph PowerShell SDK
                   https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0
#>


# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Reports.Read.All","Group.Read.All","Directory.Read.All"

# Download M365 groups activity report (last 180 days)
Write-Host "Downloading Microsoft 365 groups activity report..."
$tempFile = ".\Microsoft365GroupsActivity.csv"

Invoke-MgGraphRequest -Method GET `
    -Uri "https://graph.microsoft.com/v1.0/reports/getOffice365GroupsActivityDetail(period='D180')" `
    -OutputFilePath $tempFile
