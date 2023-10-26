<#
    .SYNOPSIS
        Get-ADWindowsServices.ps1 - Domain Controller Windows Services Health Check Script.

    .DESCRIPTION
        This script performs a list of common health checks to a specific domain, or the entire forest. The results are then compiled into a colour coded HTML report.

    .OUTPUTS
        The results are currently only output to HTML for email or as an HTML report file, or sent as an SMTP message with an HTML body.

    .PARAMETER DomainName
        Perform a health check on a specific Active Directory domain.

    .PARAMETER ReportFile
        Output the report details to a file in the current directory.

    .PARAMETER SendEmail
        Send the report via email. You have to configure the correct SMTP settings.

    .EXAMPLE
        PS> .\Get-ADWindowsServices.ps1 -ReportFile
        Checks all domains and all domain controllers in your current forest and creates a report.

    .EXAMPLE
        PS> .\Get-ADWindowsServices.ps1 -DomainName alitajran.com -ReportFile
        Checks all the domain controllers in the specified domain "alitajran.com" and creates a report.

    .EXAMPLE
        PS> .\Get-ADWindowsServices.ps1 -DomainName alitajran.com -SendEmail
        Checks all the domain controllers in the specified domain "alitajran.com" and sends the resulting report as an email message.

    .LINK
        alitajran.com/active-directory-health-check-powershell-script

    .NOTES
        Written by: ALI TAJRAN
        Website: alitajran.com
        LinkedIn: linkedin.com/in/alitajran

        Written by: RAFAEL ABEL
        LinkedIn: www.linkedin.com/in/rafael-abel-56631b22

        .CHANGELOG
            V1.00, 01/21/2023
                Initial version
            V1.01, 05/22/2023
                DNS, Ping, Uptime, DIT file drive space, DC Diag and OS drive functions removed
                Services function updated
                htmltableheader updated
                htmltablerow updated
                $htmltail
            V2.00, 08/08/2023
                Improve the logic, now the check is 5x faster than before
                Add a parameter ReportFileName, it is more friendly to test the script
            V2.01, 10/24/2023
                Add a new attribute "Status", it shows the server status up or down
                Fix some minor bugs
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false)]
    [string]$DomainName = $env:USERDOMAIN,

    [Parameter(Mandatory = $false)]
    [switch]$ReportFile,
    [string]$reportFileName,
        
    [Parameter(Mandatory = $false)]
    [switch]$SendEmail
)

#...................................
# Global Variables
#...................................

$date = Get-Date -Format "yyyy/MM/dd"
$forestName = (Get-ADForest).Name
$reporTime = Get-Date
$reportEmailSubject = "Domain Controller Windows Services Health Report"

# If parameter "ReportFileName" isn't used, assign it a value
if ( $PSBoundParameters.Keys -notcontains "ReportFileName" ) {
    $today = Get-Date -Format "yyyyMMdd"  # Format the date as desired, e.g., "yyyyMMdd" for 20231018
    $ReportFileName = "dc_health_report_$DomainName`_$today`.html"
}

$smtpsettings = @{
    To         = 'idss.ops.team@effem.com'
    From       = 'ADhealthcheck@effem.com'
    Subject    = "$forestName - $reportEmailSubject - $date"
    SmtpServer = "internalsmtp.mars-ad.net"

}

# This function gets all the domain controllers in a specified domain
Function Get-DomainControllers {
    param (
        [Alias("Domain")]
        $DomainName,
        [switch]$Recurse = $false
    )
    [array]$dcs = @()
    if ($Recurse) {
        $domains = (Get-ADDomain $DomainName).ChildDomains
        foreach ($domain in $domains ) {
            $dcs += Get-ADDomainController -Filter * -Server $domain
        }
    }
    else {
        $dcs = Get-ADDomainController -Filter * -Server $DomainName
    }
    Write-Output $dcs
}

# Define cell formats
Function New-ServerHealthHTMLTableCell {
    param( 
        $lineItem 
    )
    $htmlTableCell = $null

    switch ($($reportLine."$lineItem")) {
        "Success" { $htmlTableCell = "<td class=""pass"">$($reportLine."$lineItem")</td>" }
        "Running" { $htmlTableCell = "<td class=""pass"">$($reportLine."$lineItem")</td>" }
        "Stopped" { $htmlTableCell = "<td class=""Stopped"">$($reportLine."$lineItem")</td>" }
        "Not Found" { $htmlTableCell = "<td class=""warn"">$($reportLine."$lineItem")</td>" }
        "N/A" { $htmlTableCell = "<td class=""warn"">$($reportLine."$lineItem")</td>" }
        "Started" { $htmlTableCell = "<td class=""started"">$($reportLine."$lineItem")</td>" }
        "Passed" { $htmlTableCell = "<td class=""pass"">$($reportLine."$lineItem")</td>" }
        "Pass" { $htmlTableCell = "<td class=""pass"">$($reportLine."$lineItem")</td>" }
        "Warn" { $htmlTableCell = "<td class=""warn"">$($reportLine."$lineItem")</td>" }
        "Access Denied" { $htmlTableCell = "<td class=""warn"">$($reportLine."$lineItem")</td>" }
        "Fail" { $htmlTableCell = "<td class=""fail"">$($reportLine."$lineItem")</td>" }
        "Down" { $htmlTableCell = "<td class=""fail"">$($reportLine."$lineItem")</td>" }
        "Failed" { $htmlTableCell = "<td class=""fail"">$($reportLine."$lineItem")</td>" }
        "Could not test server uptime." { $htmlTableCell = "<td class=""fail"">$($reportLine."$lineItem")</td>" }
        "Could not test service health. " { $htmlTableCell = "<td class=""warn"">$($reportLine."$lineItem")</td>" }
        "Unknown" { $htmlTableCell = "<td class=""warn"">$($reportLine."$lineItem")</td>" }
        default { $htmlTableCell = "<td>$($reportLine."$lineItem")</td>" }
    }
    Write-Output $htmlTableCell
}

# Map service names and display names
$services = @{
    "AzureADPasswordProtectionDCAgent" = "Azure AD Password Protection DC Agent Service"
    "AATPSensor"                       = "Azure Advanced Threat Protection Sensor Service"
    "CSFalconService"                  = "CrowdStrike Falcon Sensor Service"
    "DFSR"                             = "DFS Replication Service"
    "KDC"                              = "KDC Service"
    "ErdAgent"                         = "Quest Backup Agent Service"
    "NPSrvHost"                        = "Quest Change Auditor Agent Service"
    "FRRstSvc"                         = "Quest Forest Recovery Service"
    "LanmanServer"                     = "LanmanServer Service"
    "SNMP"                             = "SNMP Service"
    "SplunkForwarder"                  = "SplunkForwarder Service"
    "WinRM"                            = "Windows Remote Management Service"
    "W32Time"                          = "Windows Time Service"
    "PCNSSVC"                          = "Password Change Notification Service"
}

# Services which are only applied to RWDCs
$rwdcServices = @("AzureADPasswordProtectionDCAgent", "ErdAgent", "FRRstSvc", "PCNSSVC")
$reportLine = @{}
Write-Host "...testing domain" $DomainName -ForegroundColor Green

# Get all domain controllers
$allDCs = Get-DomainControllers -DomainName $DomainName
$totalDCtoProcessCounter = $totalDCProcessCount = $allDCs.Count

try {
    # Loop through each domain controller
    foreach ($dc in $allDCs) {
        $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        $dcName = $dc.Name
        Write-Host "`r[$totalDCtoProcessCounter of $totalDCProcessCount]...testing domain controller $dcName $([char]27)[0K" -ForegroundColor Cyan -NoNewline
        $OFS = "`r`n"

        # Only perform the query on pingable desitination
        if (Test-Connection -ComputerName $dcName -Quiet) {
            $svcInfo = Get-Service -ComputerName $dcName

            # Initialize the $reportLine hashtable for this domain controller
            $reportLine[$dcName] = @{}

            # Loop through each service
            foreach ($serviceEntry in $services.GetEnumerator()) {
                $originalServiceName = $serviceEntry.Key
                $serviceName = $serviceEntry.Value

                if (($originalServiceName -in $rwdcServices) -and ($dc.isReadOnly -eq $true)) {

                    Write-Verbose "$originalServiceName isn't applicable on $dcName"
                    $serviceStatus = "N/A"
                    $reportLine[$dcName][$serviceName] = $serviceStatus
                    continue
                }

                # Check if the service exists on the domain controller
                if ($originalServiceName -in $svcInfo.Name) {
                    Write-Verbose "$originalServiceName is installed on $dcName"
                    try {
                        # Get the current status of the service
                        $serviceStatus = ($svcInfo | Where-Object Name -EQ $originalServiceName).Status
                        Write-Verbose "Status of $originalServiceName is $serviceStatus"

                        # Check if the service is not running
                        if ($serviceStatus -eq "Stopped") {
                            # if the service is stopped, try to start it.
                            $action = Invoke-CimMethod -Query "SELECT * FROM Win32_Service WHERE Name = '$originalServiceName'" -MethodName "StartService" -CimSession $dcName
                            # Update the service status
                            if ($action.ReturnValue -eq 0) {
                                $serviceStatus = "Started"
                                Write-Verbose "Now the status is $serviceStatus"
                            }
                        }

                        # Add the service status to the status report
                        $reportLine[$dcName][$serviceName] = $serviceStatus
                    }
                    catch {
                        # If there was an error starting the service, add the error message to the status report
                        $errorMessage = $_.Exception.Message
                        $reportLine[$dcName][$serviceName] = $errorMessage
                    }
                }
                else {
                    Write-Verbose "$originalServiceName isn't installed on $dcName"
                    # Add the "Not Found" status to the status report
                    $reportLine[$dcName][$serviceName] = 'Not Found'
                }
            }
            $thisDomainController = [PSCustomObject]@{
                "Server"                                          = ($dc.HostName).ToLower()
                "Site"                                            = $dc.Site
                "OS Version"                                      = $dc.OperatingSystem
                "Operation Master Roles"                          = ($dc.OperationMasterRoles | ForEach-Object { $_.ToString().SubString(0,1)}) -join " "
                "Status"                                          = "Up"
                "Azure AD Password Protection DC Agent Service"   = if ($reportLine[$dcName].ContainsKey("Azure AD Password Protection DC Agent Service")) { $reportLine[$dcName]["Azure AD Password Protection DC Agent Service"] } else { $AzureADPasswordProtectionDCAgentService.Status }
                "Azure Advanced Threat Protection Sensor Service" = if ($reportLine[$dcName].ContainsKey("Azure Advanced Threat Protection Sensor Service")) { $reportLine[$dcName]["Azure Advanced Threat Protection Sensor Service"] } else { $AATPSensorService.Status }
                "CrowdStrike Falcon Sensor Service"               = if ($reportLine[$dcName].ContainsKey("CrowdStrike Falcon Sensor Service")) { $reportLine[$dcName]["CrowdStrike Falcon Sensor Service"] } else { $CSFalconServiceService.Status }
                "DFS Replication Service"                         = if ($reportLine[$dcName].ContainsKey("DFS Replication Service")) { $reportLine[$dcName]["DFS Replication Service"] } else { $DFSRService.Status }
                "KDC Service"                                     = if ($reportLine[$dcName].ContainsKey("KDC Service")) { $reportLine[$dcName]["KDC Service"] } else { $kdcService.Status }
                "Quest Backup Agent Service"                      = if ($reportLine[$dcName].ContainsKey("Quest Backup Agent Service")) { $reportLine[$dcName]["Quest Backup Agent Service"] } else { $ErdAgentService.Status }
                "Quest Change Auditor Agent Service"              = if ($reportLine[$dcName].ContainsKey("Quest Change Auditor Agent Service")) { $reportLine[$dcName]["Quest Change Auditor Agent Service"] } else { $NPSrvHostService.Status }
                "Quest Forest Recovery Service"                   = if ($reportLine[$dcName].ContainsKey("Quest Forest Recovery Service")) { $reportLine[$dcName]["Quest Forest Recovery Service"] } else { $FRRstSvcService.Status }
                "LanmanServer Service"                            = if ($reportLine[$dcName].ContainsKey("LanmanServer Service")) { $reportLine[$dcName]["LanmanServer Service"] } else { $LanmanServerService.Status }
                "SNMP Service"                                    = if ($reportLine[$dcName].ContainsKey("SNMP Service")) { $reportLine[$dcName]["SNMP Service"] } else { $snmpService.Status }
                "SplunkForwarder Service"                         = if ($reportLine[$dcName].ContainsKey("SplunkForwarder Service")) { $reportLine[$dcName]["SplunkForwarder Service"] } else { $splunkForwarderService.Status }
                "Windows Remote Management Service"               = if ($reportLine[$dcName].ContainsKey("Windows Remote Management Service")) { $reportLine[$dcName]["Windows Remote Management Service"] } else { $WinRMService.Status }
                "Windows Time Service"                            = if ($reportLine[$dcName].ContainsKey("Windows Time Service")) { $reportLine[$dcName]["Windows Time Service"] } else { $w32TimeService.Status }
                "Password Change Notification Service"            = if ($reportLine[$dcName].ContainsKey("Password Change Notification Service")) { $reportLine[$dcName]["Password Change Notification Service"] } else { $PCNSSVCService.Status }
                "Processing Time"                                 = $stopWatch.Elapsed.Seconds
            }
        }
        else {
            $thisDomainController = [PSCustomObject]@{
                "Server"                                          = ($dc.HostName).ToLower()
                "Site"                                            = $dc.Site
                "OS Version"                                      = $dc.OperatingSystem
                "Operation Master Roles"                          = ($dc.OperationMasterRoles | ForEach-Object { $_.ToString().SubString(0,1)}) -join " "
                "Status"                                          = "Down"
                "Azure AD Password Protection DC Agent Service"   = "-"
                "Azure Advanced Threat Protection Sensor Service" = "-"
                "CrowdStrike Falcon Sensor Service"               = "-"
                "DFS Replication Service"                         = "-"
                "KDC Service"                                     = "-"
                "Quest Backup Agent Service"                      = "-"
                "Quest Change Auditor Agent Service"              = "-"
                "Quest Forest Recovery Service"                   = "-"
                "LanmanServer Service"                            = "-"
                "SNMP Service"                                    = "-"
                "SplunkForwarder Service"                         = "-"
                "Windows Remote Management Service"               = "-"
                "Windows Time Service"                            = "-"
                "Password Change Notification Service"            = "-"
                "Processing Time"                                 = $stopWatch.Elapsed.Seconds
            }
        }
        [array]$allTestedDomainControllers += $thisDomainController
        Remove-Variable -Name "thisDomainController"
        
        $totalDCtoProcessCounter--
    }
}
catch {
    # Handle any other exceptions that occur during the DC loop
    $errMsg = $Error[0].Exception.Message
    Write-Host $errMsg -ForegroundColor Red
}

# Common HTML head and styles
$htmlhead = @"
<html>
<style>
    BODY {
        font-family: Arial;
        font-size: 8pt;
    }

    H1 {
        font-size: 16px;
    }

    H2 {
        font-size: 14px;
    }

    H3 {
        font-size: 12px;
    }

    TABLE {
        border: 1px solid black;
        border-collapse: collapse;
        font-size: 8pt;
    }

    TH {
        border: 1px solid black;
        background: #dddddd;
        padding: 5px;
        color: #000000;
    }

    TD {
        border: 1px solid black;
        padding: 5px;
    }

    td.pass {
        background: #7FFF00;
    }

    td.started {
        background: #FFA500;
    }

    td.Running {
        background: #FFA500;
    }

    td.Stopped {
        background: #FF0000;
        color: #ffffff;
    }

    td.Not Found {
        background: #FFE600;
    }

    td.warn {
        background: #FFE600;
    }

    td.fail {
        background: #FF0000;
        color: #ffffff;
    }

    td.info {
        background: #85D4FF;
    }
</style>

<body>
    <h1 align="" left"">Domain Controller Health Check Report</h1>
    <h3 align="" left"">Generated: $reporTime</h3>
"@

# Domain Controller Health Report Table Header
$htmlTableHeader = @"
<h3>Domain Controller Health Summary</h3>
<h3>Forest: $forestName </h3>
<p>
<table>
    <tr>
        <th>Server</th>
        <th>Site</th>
        <th>OS Version</th>
        <th>Operation Master Roles</th>
        <th>Status</th>
        <th>Azure AD Password Protection DC Agent Service</th>
        <th>Azure Advanced Threat Protection Sensor Service</th>
        <th>CrowdStrike Falcon Sensor Service</th>
        <th>DFS Replication Service</th>
        <th>KDC Service</th>
        <th>Quest Backup Agent Service</th>
        <th>Quest Change Auditor Agent Service</th>
        <th>Quest Forest Recovery Service</th>
        <th>LanmanServer Service</th>
        <th>SNMP Service</th>
        <th>SplunkForwarder Service</th>
        <th>Windows Remote Management Service</th>
        <th>Windows Time Service</th>
        <th>Password Change Notification Service</th>
        <th>Processing Time</th>
    </tr>
"@

# Domain Controller Health Report Table
$serverHealthHtmlTable = $serverHealthHtmlTable + $htmlTableHeader

# This section will process through the $allTestedDomainControllers array object and create and colour the HTML table based on certain conditions.
foreach ($reportLine in $allTestedDomainControllers) {
      
    if (Test-Path variable:fsmoRoleHTML) {
        Remove-Variable fsmoRoleHTML
    }

    if (($reportLine."Operation Master Roles") -gt 0) {
        foreach ($line in $reportLine."Operation Master Roles") {
            if ($line.count -gt 0) {
                [array]$fsmoRoleHTML += $line.ToString() + '<br>'
            }
        }
    }

    else {
        $fsmoRoleHTML += 'None<br>'
    }

    $htmlTableRow = "<tr>"
    $htmlTableRow += "<td>$($reportLine.server)</td>"
    $htmlTableRow += "<td>$($reportLine.site)</td>"
    $htmlTableRow += "<td>$($reportLine."OS Version")</td>"
    $htmlTableRow += "<td>$($fsmoRoleHTML)</td>"
    $htmlTableRow += (New-ServerHealthHTMLTableCell "Status")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "Azure AD Password Protection DC Agent Service")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "Azure Advanced Threat Protection Sensor Service")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "CrowdStrike Falcon Sensor Service")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "DFS Replication Service")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "KDC Service")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "Quest Backup Agent Service")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "Quest Change Auditor Agent Service")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "Quest Forest Recovery Service")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "LanmanServer Service")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "SNMP Service")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "SplunkForwarder Service")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "Windows Remote Management Service")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "Windows Time Service")
    $htmlTableRow += (New-ServerHealthHTMLTableCell "Password Change Notification Service")
    
    $averageProcessingTime = ($allTestedDomainControllers | Measure-Object -Property "Processing Time" -Average).Average
    if ($($reportLine."Processing Time") -gt $averageProcessingTime) {
        $htmlTableRow += "<td class=""warn"">$($reportLine."Processing Time")</td>"        
    }
    elseif ($($reportLine."Processing Time") -le $averageProcessingTime) {
        $htmlTableRow += "<td class=""pass"">$($reportLine."Processing Time")</td>"
    }
          
    [array]$serverHealthHtmlTable = $serverHealthHtmlTable + $htmlTableRow
}

$serverHealthHtmlTable = $serverHealthHtmlTable + "</table></p>"

$htmltail = @"
* <b>Operation Master Roles</b>: <strong>S</strong> - SchemaMaster, <strong>D</strong> - DomainNamingMaster, <strong>P</strong> - PDCEmulator, <strong>R</strong> - RIDMaster, <strong>I</strong> - InfrastructureMaster<br>
* <strong>Ready-Only Domain Controllers</strong> do <em>NOT</em> have <u>Azure AD Password Protection DC Agent</u>, <u>Quest Backup Agent</u>, <u>Quest Forest
Recovery</u> and <u>Password Change Notification Service services running</u>. Failing this test is normal.<br>
* DNS test is performed using Resolve-DnsName. This cmdlet is only available from Windows 2012 onwards.
</body>
</html>
"@

$htmlreport = $htmlhead + $serversummaryhtml + $dagsummaryhtml + $serverHealthHtmlTable + $dagreportbody + $htmltail

if ($ReportFile) {
    $htmlreport | Out-File $reportFileName -Encoding UTF8
}

if ($SendEmail) {
    # Send email message
    Send-MailMessage @smtpsettings -Body $htmlreport -BodyAsHtml -Encoding ([System.Text.Encoding]::UTF8)
}