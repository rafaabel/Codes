<#
    .SYNOPSIS
    Get-ADEventIDs.ps1 - Domain Controller Event IDs Health Check Script.

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
    .\Get-ADEventIDs.ps1 -ReportFile
    Checks all domains and all domain controllers in your current forest and creates a report.

    .EXAMPLE
    .\Get-ADEventIDs.ps1 -DomainName alitajran.com -ReportFile
    Checks all the domain controllers in the specified domain "alitajran.com" and creates a report.

    .EXAMPLE
    .\Get-ADEventIDs.ps1 -DomainName alitajran.com -SendEmail
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
    V1.01, 05/26/2023 - 
        DNS, Ping, Uptime, DIT file drive space, Services, DC Diag and OS drive functions removed
        Event ID function created
        htmltableheader updated
        htmltablerow updated
        $htmltail l 
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
$reportemailsubject = "Domain Controller Event IDs Health Report"

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

# This function gets all Event IDs in a specified domain and group by server name.
Function Get-ADEventIDs($DomainNameInput) {
    Write-Verbose "..running function ADEventIDs"

    If ((Test-Connection $DomainNameInput -Count 1 -quiet) -eq $True) {
        $systemEvents = Get-WinEvent -FilterHashtable @{LogName = 'System'; ID = 2004; StartTime = (Get-Date).AddDays(-1) } -ComputerName $DomainNameInput -ErrorAction SilentlyContinue
        $directoryServiceEvents = Get-WinEvent -FilterHashtable @{LogName = 'Directory Service'; ID = 602, 623, 1388, 1519, 1988, 2042, 2095, 2866; StartTime = (Get-Date).AddDays(-1) } -ComputerName $DomainNameInput -ErrorAction SilentlyContinue
        $dnsServerEvents = Get-WinEvent -FilterHashtable @{LogName = 'DNS Server'; ID = 4010, 4016; StartTime = (Get-Date).AddDays(-1) } -ComputerName $DomainNameInput -ErrorAction SilentlyContinue

        $thisEventIDs += foreach ($systemEvent in $systemEvents) {
            [PSCustomObject]@{
                Server    = "$($DomainNameInput)"
                EventType = "System"
                EntryType = $systemEvent.LevelDisplayName
                EventID   = $systemEvent.Id
                Message   = $systemEvent.Message
            }
        }

        $thisEventIDs += foreach ($directoryServiceEvent in $directoryServiceEvents) {
            [PSCustomObject]@{
                Server    = "$($DomainNameInput)"
                EventType = "Directory Service"
                EntryType = $directoryServiceEvent.LevelDisplayName
                EventID   = $directoryServiceEvent.Id
                Message   = $directoryServiceEvent.Message
            }
        }

        $thisEventIDs += foreach ($dnsServerEvent in $dnsServerEvents) {
            [PSCustomObject]@{
                Server    = "$($DomainNameInput)"
                EventType = "DNS Server"
                EntryType = $dnsServerEvent.LevelDisplayName
                EventID   = $dnsServerEvent.Id
                Message   = $dnsServerEvent.Message
            }
        }

        $thisEventIDs = $thisEventIDs | Group-Object Server | ForEach-Object {
            $server = $_.Group[0].Server
            $eventType = ($_.Group | Select-Object -ExpandProperty EventType -Unique)
            $entryType = ($_.Group | Select-Object -ExpandProperty EntryType -Unique) 
            $eventID = ($_.Group | Select-Object -ExpandProperty EventID -Unique) 
            $message = ($_.Group | Select-Object -ExpandProperty Message -Unique) 

            [PSCustomObject]@{
                Server    = $server
                EventType = @($eventType)
                EntryType = @($entryType)
                EventID   = @($eventID)
                Message   = @($message)
            }
        }
    }

    Else {
        $thisEventIDs = [PSCustomObject]@{
            Server    = $server
            EventType = 'Failed'
            EntryType = 'Failed'
            EventID   = 'Failed'
            Message   = 'Failed'
        }
    }
    return $thisEventIDs 
}

# This function checks the server OS version.nt
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
        $thisDomainController | Add-Member NoteProperty -name "Event Type" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Entry Type" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Event ID" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Message" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Processing Time" -Value $null
        $OFS = "`r`n"
        $thisDomainController.Server = ($domainController.HostName).ToLower()
        $thisDomainController.Site = $domainController.Site
        $thisDomainController."OS Version" = (Get-DomainControllerOSVersion $domainController.hostname)
        $thisDomainController."Operation Master Roles" = $domainController.OperationMasterRoles
        $thisDomainController."Event Type" = (Get-ADEventIDs $domainController.HostName).EventType
        $thisDomainController."Entry Type" = (Get-ADEventIDs $domainController.HostName).EntryType
        $thisDomainController."Event ID" = (Get-ADEventIDs $domainController.HostName).EventID
        $thisDomainController."Message" = (Get-ADEventIDs $domainController.HostName).Message
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
                        <th>Event Type</th>
                        <th>Entry Type</th>
                        <th>Event ID</th>
                        <th>Message</th>
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

    if (Test-Path variable:osEventType) {
        Remove-Variable osEventType
    }
    
    if (($reportline."Event Type") -gt 0) {
        foreach ($line in $reportline."Event Type") {
            if ($line.count -gt 0) {
                [array]$osEventType += $line.ToString() + '<br>'
            }
        }
    }

    else {
        $osEventType += 'Passed<br>'
    }

    if (Test-Path variable:osEntryType) {
        Remove-Variable osEntryType
    }

    if (($reportline."Entry Type") -gt 0) {
        foreach ($line in $reportline."Entry Type") {
            if ($line.count -gt 0) {
                [array]$osEntryType += $line.ToString() + '<br>'
            }
        }
    }

    else {
        $osEntryType += 'Passed<br>'
    }

    if (Test-Path variable:osEventID) {
        Remove-Variable osEventID
    }

    if (($reportline."Event ID") -gt 0) {
        foreach ($line in $reportline."Event ID") {
            if ($line.count -gt 0) {
                [array]$osEventID += $line.ToString() + '<br>'
            }
        }
    }

    else {
        $osEventID += 'Passed<br>'
    }

    if (Test-Path variable:osEventMessage) {
        Remove-Variable osEventMessage
    }

    if (($reportline."Message") -gt 0) {
        foreach ($line in $reportline."Message") {
            if ($line.count -gt 0) {
                [array] $osEventMessage += $line.ToString() + '<br>'
            }
        }
    }

    else {
        $osEventMessage += 'Passed<br>'
    }

    $htmltablerow = "<tr>"
    $htmltablerow += "<td>$($reportline.server)</td>"
    $htmltablerow += "<td>$($reportline.site)</td>"
    $htmltablerow += "<td>$($reportline."OS Version")</td>"
    $htmltablerow += "<td>$($fsmoRoleHTML)</td>"

    if ($osEntryType -eq "Failed") {
        $htmltablerow += "<td class=""warn"">Could not retrieve server Events.</td>"
        $htmltablerow += "<td class=""warn"">$osEntryType</td>"
        $htmltablerow += "<td class=""warn"">$osEventID</td>"
        $htmltablerow += "<td class=""warn"">$osEventMessage</td>"       
    }

    elseif ($osEntryType -eq "Error<br>") {
        $htmltablerow += "<td class=""fail"">$osEventType</td>"
        $htmltablerow += "<td class=""fail"">$osEntryType</td>"
        $htmltablerow += "<td class=""fail"">$osEventID</td>"
        $htmltablerow += "<td class=""fail"">$osEventMessage</td>"
    }
    elseif ($osEntryType -eq "Warning<br>") {
        $htmltablerow += "<td class=""warn"">$osEventType</td>"
        $htmltablerow += "<td class=""warn"">$osEntryType</td>"
        $htmltablerow += "<td class=""warn"">$osEventID</td>"
        $htmltablerow += "<td class=""warn"">$osEventMessage</td>"
    }

    elseif ($osEntryType -contains "Error<br>" -and $osEntryType -contains "Warning<br>" ) {
        $htmltablerow += "<td class=""fail"">$osEventType</td>"
        $htmltablerow += "<td class=""fail"">$osEntryType</td>"
        $htmltablerow += "<td class=""fail"">$osEventID</td>"
        $htmltablerow += "<td class=""fail"">$osEventMessage</td>"
    }
    else {
        $htmltablerow += "<td class=""pass"">$osEventType</td>"
        $htmltablerow += "<td class=""pass"">$osEntryType</td>"
        $htmltablerow += "<td class=""pass"">$osEventID</td>"
        $htmltablerow += "<td class=""pass"">$osEventMessage</td>"
    }

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

$htmltail = "* Windows 2003 Domain Controllers do not have the NTDS Service running. Failing this test is normal for that version of Windows.<br>
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

