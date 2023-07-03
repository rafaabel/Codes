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
    .\Get-ADWindowsServices.ps1 -ReportFile
    Checks all domains and all domain controllers in your current forest and creates a report.

    .EXAMPLE
    .\Get-ADWindowsServices.ps1 -DomainName alitajran.com -ReportFile
    Checks all the domain controllers in the specified domain "alitajran.com" and creates a report.

    .EXAMPLE
    .\Get-ADWindowsServices.ps1 -DomainName alitajran.com -SendEmail
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
    V1.00, 01/21/2023 - Initial version
    V1.01, 05/22/2023 - 
        DNS, Ping, Uptime, DIT file drive space, DC Diag and OS drive functions removed
        Services function updated
        htmltableheader updated
        htmltablerow updated
        $htmltail 
    V1.02, 06/20/2023 -  Updated Domain Controller Windows Services function to not verify certain service in Read-Only Domain Controllers 
#>
[CmdletBinding()]
Param(
    [Parameter( Mandatory = $false)]
    [string]$DomainName,

    [Parameter( Mandatory = $false)]
    [switch]$ReportFile,
        
    [Parameter( Mandatory = $false)]
    [switch]$SendEmail
)

#...................................
# Global Variables
#...................................

$now = Get-Date
$date = $now.ToShortDateString()
[array]$allDomainControllers = @()
$reportime = Get-Date
$reportemailsubject = "Domain Controller Windows Services Health Report"

$smtpsettings = @{
    To         = 'idss.ops.team@effem.com'
    From       = 'ADhealthcheck@effem.com'
    Subject    = "$reportemailsubject - $now"
    SmtpServer = "internalsmtp.mars-ad.net"
}

#...................................
# Functions
#...................................

# This function gets all the domains in the forest.
Function Get-AllDomains() {
    Write-Verbose "..running function Get-AllDomains"
    $allDomains = (Get-ADForest).Domains 
    return $allDomains
}

# This function gets all the domain controllers in a specified domain.
Function Get-AllDomainControllers ($DomainNameInput) {
    Write-Verbose "..running function Get-AllDomainControllers" 
    [array]$allDomainControllers = Get-ADDomainController -Filter * -Server $DomainNameInput
    return $allDomainControllers
}

<# This function checks the following services:

Azure AD Password Protection DC Agent - (AzureADPasswordProtectionDCAgent)
Azure Advanced Threat Protection Sensor - (AATPSensor)
CrowdStrike Falcon Sensor Service - (CSFalconService)
DFS Replication - (DFSR)
Kerberos Key Distribution Center - (Kdc) 
Quest Backup Agent - (ErdAgent) 
Quest Change Auditor Agent - (NPSrvHost) 
Quest Forest Recovery Service - (FRRstSvc) 
Server - (LanmanServer) 
SNMP Service - (SNMP) 
SplunkForwarder Service - (SplunkForwarder) 
Windows Remote Management - (WinRM)
Windows Time - (W32Time)
Password Change Notification Service - (PCNSSVC)

#>

Function Get-DomainControllerWindowsServices($DomainNameInput) {
    Write-Verbose "..running function DomainControllerWindowsServices"

    If ((Test-Connection $DomainNameInput -Count 1 -quiet) -eq $True) {
        $thisDomainControllerWindowsServicesTestResult = New-Object PSObject
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name AzureADPasswordProtectionDCAgentService -Value $null
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name AATPSensorService -Value $null
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name CSFalconService -Value $null
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name DFSRService -Value $null
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name kdcService -Value $null
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name ErdAgentService -Value $null
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name NPSrvHostService -Value $null
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name FRRstSvcService -Value $null
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name LanmanServerService -Value $null
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name SNMPService -Value $null
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name SplunkForwarderService -Value $null
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name WinRMService -Value $null
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name W32TimeService -Value $null
        $thisDomainControllerWindowsServicesTestResult | Add-Member NoteProperty -name PCNSSVCService -Value $null

        
        If ((Get-ADDomainController -Server $DomainNameInput).isReadOnly -eq 'False') {
            $thisDomainControllerWindowsServicesTestResult.AzureADPasswordProtectionDCAgentService = 'N/A'
        }
        Elseif ((Get-Service -ComputerName $DomainNameInput -Name AzureADPasswordProtectionDCAgent -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.AzureADPasswordProtectionDCAgentService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.AzureADPasswordProtectionDCAgentService = 'Fail'
        }

        If ((Get-Service -ComputerName $DomainNameInput -Name AATPSensor -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.AATPSensorService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.AATPSensorService = 'Fail'
        }
        
        If ((Get-Service -ComputerName $DomainNameInput -Name CSFalconService -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.CSFalconService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.CSFalconService = 'Fail'
        }

        If ((Get-Service -ComputerName $DomainNameInput -Name DFSR -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.DFSRService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.DFSRService = 'Fail'
        }

        If ((Get-Service -ComputerName $DomainNameInput -Name kdc -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.kdcService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.kdcService = 'Fail'
        }

        If ((Get-ADDomainController -Server $DomainNameInput).isReadOnly -eq 'False') {
            $thisDomainControllerWindowsServicesTestResult.ErdAgentService = 'N/A'
        }
        Elseif ((Get-Service -ComputerName $DomainNameInput -Name ErdAgent -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.ErdAgentService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.ErdAgentService = 'Fail'
        }

        If ((Get-Service -ComputerName $DomainNameInput -Name NPSrvHost -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.NPSrvHostService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.NPSrvHostService = 'Fail'
        }

        If ((Get-ADDomainController -Server $DomainNameInput).isReadOnly -eq 'False') {
            $thisDomainControllerWindowsServicesTestResult.FRRstSvcService = 'N/A'
        }
        Elseif ((Get-Service -ComputerName $DomainNameInput -Name FRRstSvc  -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.FRRstSvcService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.FRRstSvcService = 'Fail'
        }

        If ((Get-Service -ComputerName $DomainNameInput -Name LanmanServer -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.LanmanServerService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.LanmanServerService = 'Fail'
        }

        If ((Get-Service -ComputerName $DomainNameInput -Name SNMP -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.SNMPService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.SNMPService = 'Fail'
        }

        If ((Get-Service -ComputerName $DomainNameInput -Name SplunkForwarder -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.SplunkForwarderService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.SplunkForwarderService = 'Fail'
        }

        If ((Get-Service -ComputerName $DomainNameInput -Name WinRM -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.WinRMService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.WinRMService = 'Fail'
        }

        If ((Get-Service -ComputerName $DomainNameInput -Name W32Time -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.W32TimeService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.W32TimeService = 'Fail'
        }

        If ((Get-ADDomainController -Server $DomainNameInput).isReadOnly -eq 'False') {
            $thisDomainControllerWindowsServicesTestResult.PCNSSVCService = 'N/A'
        }
        Elseif ((Get-Service -ComputerName $DomainNameInput -Name PCNSSVC -ErrorAction SilentlyContinue).Status -eq 'Running') {
            $thisDomainControllerWindowsServicesTestResult.PCNSSVCService = 'Success'
        }
        Else {
            $thisDomainControllerWindowsServicesTestResult.PCNSSVCService = 'Fail'
        }
    }
    Else {
 
        $thisDomainControllerWindowsServicesTestResult.AzureADPasswordProtectionDCAgentService = 'Fail'
        $thisDomainControllerWindowsServicesTestResult.AATPSensorService = 'Fail'
        $thisDomainControllerWindowsServicesTestResult.CSFalconService = 'Fail'
        $thisDomainControllerWindowsServicesTestResult.DFSRService = 'Fail'
        $thisDomainControllerWindowsServicesTestResult.kdcService = 'Fail'
        $thisDomainControllerWindowsServicesTestResult.ErdAgentService = 'Fail'
        $thisDomainControllerWindowsServicesTestResult.NPSrvHostService = 'Fail'
        $thisDomainControllerWindowsServicesTestResult.FRRstSvcService = 'Fail'
        $thisDomainControllerWindowsServicesTestResult.LanmanServerService = 'Fail'
        $thisDomainControllerWindowsServicesTestResult.SNMPService = 'Fail'
        $thisDomainControllerWindowsServicesTestResult.SplunkForwarderService = 'Fail'
        $thisDomainControllerWindowsServicesTestResult.WinRMService = 'Fail'
        $thisDomainControllerWindowsServicesTestResult.W32TimeService = 'Fail'
        $thisDomainControllerWindowsServicesTestResult.PCNSSVCService = 'Fail'
        
    }
    return $thisDomainControllerWindowsServicesTestResult
       
}

# This function checks the server OS version.
Function Get-DomainControllerOSVersion ($DomainNameInput) {
    Write-Verbose "..running function Get-DomainControllerOSVersion"
    $W32OSVersion = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $DomainNameInput -ErrorAction SilentlyContinue).Caption
    return $W32OSVersion
}

# This function generates HTML code from the results of the above functions.
Function New-ServerHealthHTMLTableCell() {
    param( $lineitem )
    $htmltablecell = $null

    switch ($($reportline."$lineitem")) {
        $success { $htmltablecell = "<td class=""pass"">$($reportline."$lineitem")</td>" }
        "Success" { $htmltablecell = "<td class=""pass"">$($reportline."$lineitem")</td>" }
        "Passed" { $htmltablecell = "<td class=""pass"">$($reportline."$lineitem")</td>" }
        "Pass" { $htmltablecell = "<td class=""pass"">$($reportline."$lineitem")</td>" }
        "Warn" { $htmltablecell = "<td class=""warn"">$($reportline."$lineitem")</td>" }
        "Access Denied" { $htmltablecell = "<td class=""warn"">$($reportline."$lineitem")</td>" }
        "Fail" { $htmltablecell = "<td class=""fail"">$($reportline."$lineitem")</td>" }
        "Failed" { $htmltablecell = "<td class=""fail"">$($reportline."$lineitem")</td>" }
        "Could not test server uptime." { $htmltablecell = "<td class=""fail"">$($reportline."$lineitem")</td>" }
        "Could not test service health. " { $htmltablecell = "<td class=""warn"">$($reportline."$lineitem")</td>" }
        "Unknown" { $htmltablecell = "<td class=""warn"">$($reportline."$lineitem")</td>" }
        default { $htmltablecell = "<td>$($reportline."$lineitem")</td>" }
    }
    return $htmltablecell
}

if (!($DomainName)) {
    Write-Host "..no domain specified, using all domains in forest" -ForegroundColor Yellow
    $allDomains = Get-AllDomains
    $reportFileName = 'forest_health_report_' + (Get-ADForest).name + '.html'
}

Else {
    Write-Host "..domain name specified on cmdline"
    $allDomains = $DomainName
    $reportFileName = 'dc_health_report_' + $DomainName + '.html'
}

foreach ($domain in $allDomains) {
    Write-Host "..testing domain" $domain -ForegroundColor Green
    [array]$allDomainControllers = Get-AllDomainControllers $domain
    $totalDCtoProcessCounter = $allDomainControllers.Count
    $totalDCProcessCount = $allDomainControllers.Count 

    foreach ($domainController in $allDomainControllers) {
        $stopWatch = [system.diagnostics.stopwatch]::StartNew()
        Write-Host "..testing domain controller" "(${totalDCtoProcessCounter} of ${totalDCProcessCount})" $domainController.HostName -ForegroundColor Cyan
        $thisDomainController = New-Object PSObject
        $thisDomainController | Add-Member NoteProperty -name Server -Value $null
        $thisDomainController | Add-Member NoteProperty -name Site -Value $null
        $thisDomainController | Add-Member NoteProperty -name "OS Version" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Operation Master Roles" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Azure AD Password Protection DC Agent Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Azure Advanced Threat Protection Sensor Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "CrowdStrike Falcon Sensor Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "DFS Replication Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "KDC Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Quest Backup Agent Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Quest Change Auditor Agent Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Quest Forest Recovery Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "LanmanServer Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "SNMP Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "SplunkForwarder Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Windows Remote Management Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Windows Time Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Password Change Notification Service Service" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Processing Time" -Value $null
        $OFS = "`r`n"
        $thisDomainController.Server = ($domainController.HostName).ToLower()
        $thisDomainController.Site = $domainController.Site
        $thisDomainController."OS Version" = (Get-DomainControllerOSVersion $domainController.hostname)
        $thisDomainController."Operation Master Roles" = $domainController.OperationMasterRoles
        $thisDomainController."Azure AD Password Protection DC Agent Service" = (Get-DomainControllerWindowsServices $domainController.HostName).AzureADPasswordProtectionDCAgentService
        $thisDomainController."Azure Advanced Threat Protection Sensor Service" = (Get-DomainControllerWindowsServices $domainController.HostName).AATPSensorService
        $thisDomainController."CrowdStrike Falcon Sensor Service" = (Get-DomainControllerWindowsServices $domainController.HostName).CSFalconService
        $thisDomainController."DFS Replication Service" = (Get-DomainControllerWindowsServices $domainController.HostName).DFSRService
        $thisDomainController."KDC Service" = (Get-DomainControllerWindowsServices $domainController.HostName).kdcService
        $thisDomainController."Quest Backup Agent Service" = (Get-DomainControllerWindowsServices $domainController.HostName).ErdAgentService
        $thisDomainController."Quest Change Auditor Agent Service" = (Get-DomainControllerWindowsServices $domainController.HostName).NPSrvHostService
        $thisDomainController."Quest Forest Recovery Service" = (Get-DomainControllerWindowsServices $domainController.HostName).FRRstSvcService
        $thisDomainController."LanmanServer Service" = (Get-DomainControllerWindowsServices $domainController.HostName).LanmanServerService
        $thisDomainController."SNMP Service" = (Get-DomainControllerWindowsServices $domainController.HostName).SNMPService
        $thisDomainController."SplunkForwarder Service" = (Get-DomainControllerWindowsServices $domainController.HostName).SplunkForwarderService
        $thisDomainController."Windows Remote Management Service" = (Get-DomainControllerWindowsServices $domainController.HostName).WinRMService
        $thisDomainController."Windows Time Service" = (Get-DomainControllerWindowsServices $domainController.HostName).W32TimeService
        $thisDomainController."Password Change Notification Service Service" = (Get-DomainControllerWindowsServices $domainController.HostName).PCNSSVCService
        $thisDomainController."Processing Time" = $stopWatch.Elapsed.Seconds

        [array]$allTestedDomainControllers += $thisDomainController
        $totalDCtoProcessCounter -- 
    }

}

# Common HTML head and styles
$htmlhead = "<html>
                <style>
                BODY{font-family: Arial; font-size: 8pt;}
                H1{font-size: 16px;}
                H2{font-size: 14px;}
                H3{font-size: 12px;}
                TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}
                TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}
                TD{border: 1px solid black; padding: 5px; }
                td.pass{background: #7FFF00;}
                td.warn{background: #FFE600;}
                td.fail{background: #FF0000; color: #ffffff;}
                td.info{background: #85D4FF;}
                </style>
                <body>
                <h1 align=""left"">Domain Controller Health Check Report</h1>
                <h3 align=""left"">Generated: $reportime</h3>"
                   
# Domain Controller Health Report Table Header
$htmltableheader = "<h3>Domain Controller Health Summary</h3>
                        <h3>Forest: $((Get-ADForest).Name)</h3>
                        <p>
                        <table>
                        <tr>
                        <th>Server</th>
                        <th>Site</th>
                        <th>OS Version</th>
                        <th>Operation Master Roles</th>
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
                        <th>Password Change Notification Service Service</th>
                        <th>Processing Time</th>
                        </tr>"

# Domain Controller Health Report Table
$serverhealthhtmltable = $serverhealthhtmltable + $htmltableheader

# This section will process through the $allTestedDomainControllers array object and create and colour the HTML table based on certain conditions.
foreach ($reportline in $allTestedDomainControllers) {
      
    if (Test-Path variable:fsmoRoleHTML) {
        Remove-Variable fsmoRoleHTML
    }

    if (($reportline."Operation Master Roles") -gt 0) {
        foreach ($line in $reportline."Operation Master Roles") {
            if ($line.count -gt 0) {
                [array]$fsmoRoleHTML += $line.ToString() + '<br>'
            }
        }
    }

    else {
        $fsmoRoleHTML += 'None<br>'
    }

    $htmltablerow = "<tr>"
    $htmltablerow += "<td>$($reportline.server)</td>"
    $htmltablerow += "<td>$($reportline.site)</td>"
    $htmltablerow += "<td>$($reportline."OS Version")</td>"
    $htmltablerow += "<td>$($fsmoRoleHTML)</td>"
    $htmltablerow += (New-ServerHealthHTMLTableCell "Azure AD Password Protection DC Agent Service")
    $htmltablerow += (New-ServerHealthHTMLTableCell "Azure Advanced Threat Protection Sensor Service")
    $htmltablerow += (New-ServerHealthHTMLTableCell "CrowdStrike Falcon Sensor Service")
    $htmltablerow += (New-ServerHealthHTMLTableCell "DFS Replication Service")
    $htmltablerow += (New-ServerHealthHTMLTableCell "KDC Service")
    $htmltablerow += (New-ServerHealthHTMLTableCell "Quest Backup Agent Service")
    $htmltablerow += (New-ServerHealthHTMLTableCell "Quest Change Auditor Agent Service")
    $htmltablerow += (New-ServerHealthHTMLTableCell "Quest Forest Recovery Service")
    $htmltablerow += (New-ServerHealthHTMLTableCell "LanmanServer Service")
    $htmltablerow += (New-ServerHealthHTMLTableCell "SNMP Service")
    $htmltablerow += (New-ServerHealthHTMLTableCell "SplunkForwarder Service")
    $htmltablerow += (New-ServerHealthHTMLTableCell "Windows Remote Management Service")
    $htmltablerow += (New-ServerHealthHTMLTableCell "Windows Time Service")
    $htmltablerow += (New-ServerHealthHTMLTableCell "Password Change Notification Service Service")  
    
    $averageProcessingTime = ($allTestedDomainControllers | measure -Property "Processing Time" -Average).Average
    if ($($reportline."Processing Time") -gt $averageProcessingTime) {
        $htmltablerow += "<td class=""warn"">$($reportline."Processing Time")</td>"        
    }
    elseif ($($reportline."Processing Time") -le $averageProcessingTime) {
        $htmltablerow += "<td class=""pass"">$($reportline."Processing Time")</td>"
    }
          
    [array]$serverhealthhtmltable = $serverhealthhtmltable + $htmltablerow
}

$serverhealthhtmltable = $serverhealthhtmltable + "</table></p>"

$htmltail = "* Ready-Only Domain Controllers do not have Azure AD Password Protection DC Agent, Quest Backup Agent, Quest Forest Recovery and Password Change Notification Service services running. Failing this test is normal.<br>
    * Windows 2003 Domain Controllers do not have the NTDS Service running. Failing this test is normal for that version of Windows.<br>
    * DNS test is performed using Resolve-DnsName. This cmdlet is only available from Windows 2012 onwards.
                </body>
                </html>"

$htmlreport = $htmlhead + $serversummaryhtml + $dagsummaryhtml + $serverhealthhtmltable + $dagreportbody + $htmltail

if ($ReportFile) {
    $htmlreport | Out-File $reportFileName -Encoding UTF8
}

if ($SendEmail) {
    # Send email message
    Send-MailMessage @smtpsettings -Body $htmlreport -BodyAsHtml -Encoding ([System.Text.Encoding]::UTF8)

}

