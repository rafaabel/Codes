<#
    .SYNOPSIS
    Get-ADDFSRBacklog.ps1 - Domain Controller DFSR Health Check Script.

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
    .\Get-ADDFSRBacklog.ps1 -ReportFile
    Checks all domains and all domain controllers in your current forest and creates a report.

    .EXAMPLE
    .\Get-ADDFSRBacklog.ps1 -DomainName alitajran.com -ReportFile
    Checks all the domain controllers in the specified domain "alitajran.com" and creates a report.

    .EXAMPLE
    .\Get-ADDFSRBacklog.ps1 -DomainName alitajran.com -SendEmail
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
    V1.01, 05/29/2023 - 
        DNS, Ping, Uptime, DIT file drive space, Services, DC Diag and OS drive functions removed
        DFSR backlog function created
        htmltableheader updated
        htmltablerow updated
        $htmltail updated
    V1.02, 06/15/2023 - Try / Catch statement added in DFSR backlog function and HTML conditional formatting updated
    v1.03, 06/20/2023 - Updated DFSR backlog function and HTML code to find PDC emulator (source server) of every domain. 
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

$date = Get-Date -Format "yyyy/MM/dd"
$forestName = (Get-ADForest).Name
[array]$allDomainControllers = @()
$reportime = Get-Date
$reportemailsubject = "Domain Controller DFSR Health Report"

$smtpsettings = @{
    To         = 'idss.ops.team@effem.com'
    From       = 'ADhealthcheck@effem.com'
    Subject    = "$forestName - $reportemailsubject - $date"
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

# This function gets all DFSR backlog in a specified domain
Function Get-ADDFSRBackLog ($DomainNameInput, $domain) {
    Write-Verbose "...running function DFSR Backlog"

    If ((Test-Connection $DomainNameInput -Count 1 -quiet) -eq $True) {

        $sourceServer = (Get-ADDomain $domain | Select-Object PDCEmulator).PDCEmulator
        $destinationServer = $DomainNameInput
        $groupName = "Domain System Volume"
        $folderName = "SYSVOL Share"
        try {
            $dfsrBackLog = (Get-DfsrBacklog -SourceComputerName $sourceServer -DestinationComputerName $destinationServer -GroupName $groupName  -FolderName $folderName -ErrorAction Stop).Count
        }
        catch [exception] {
            $dfsrBackLog = 'WMI Failure'
        }

        [PSCustomObject]@{
            SourceServer      = $sourceServer
            DestinationServer = $destinationServer
            GroupName         = $groupName
            FolderName        = $folderName
            DFSRBacklog       = $dfsrBackLog
        }
    }

    Else {
        $dfsrBackLog = "Failed"  
    }
    return $dfsrBackLog
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
        $thisDomainController | Add-Member NoteProperty -name "Source Server" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Destination Server" -Value $null
        $thisDomainController | Add-Member NoteProperty -name Site -Value $null
        $thisDomainController | Add-Member NoteProperty -name "OS Version" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Operation Master Roles" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Group Name" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Folder Name" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "DFSR Backlog ( > 99)" -Value $null
        $thisDomainController | Add-Member NoteProperty -name "Processing Time" -Value $null
        $OFS = "`r`n"
        $thisDomainController."Source Server" = (Get-ADDFSRBackLog -DomainNameInput $domainController.HostName -domain $domain).SourceServer.ToLower() 
        $thisDomainController."Destination Server" = ($domainController.HostName).ToLower()
        $thisDomainController.Site = $domainController.Site
        $thisDomainController."OS Version" = (Get-DomainControllerOSVersion -DomainNameInput $domainController.hostname)
        $thisDomainController."Operation Master Roles" = $domainController.OperationMasterRoles
        $thisDomainController."Group Name" = (Get-ADDFSRBackLog -DomainNameInput $domainController.HostName -domain $domain).GroupName
        $thisDomainController."Folder Name" = (Get-ADDFSRBackLog -DomainNameInput $domainController.HostName -domain $domain).FolderName
        $thisDomainController."DFSR Backlog ( > 99)" = (Get-ADDFSRBackLog -DomainNameInput $domainController.HostName -domain $domain).DFSRBacklog
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
                        <h3>Forest: $forestName </h3>
                        <p>
                        <table>
                        <tr>
                        <th>Source Server</th>
                        <th>Destination Server</th>
                        <th>Site</th>
                        <th>OS Version</th>
                        <th>Operation Master Roles</th>
                        <th>Group Name</th>
                        <th>Folder Name</th>
                        <th>DFSR Backlog ( > 99)</th>
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
    $htmltablerow += "<td>$($reportline."Source Server")</td>"
    $htmltablerow += "<td>$($reportline."Destination Server")</td>"
    $htmltablerow += "<td>$($reportline.site)</td>"
    $htmltablerow += "<td>$($reportline."OS Version")</td>"
    $htmltablerow += "<td>$($fsmoRoleHTML)</td>"
    $htmltablerow += (New-ServerHealthHTMLTableCell "Group Name")
    $htmltablerow += (New-ServerHealthHTMLTableCell "Folder Name") 

    $osDfsrBackLog = $reportline."DFSR Backlog ( > 99)"

    if ($osDfsrBackLog -eq "WMI Failure") {
        $htmltablerow += "<td class=""warn"">Could not test server DFSR Backlog.</td>"        
    }
    elseif ($osDfsrBackLog -eq "Failed") {
        $htmltablerow += "<td class=""warn"">Could not test server DFSR Backlog.</td>"        
    }
    elseif ($osDfsrBackLog -gt 70 -and $osDfsrBackLog -le 99) {
        $htmltablerow += "<td class=""warn"">$osDfsrBackLog</td>"
    }
    elseif ($osDfsrBackLog -gt 99) {
        $htmltablerow += "<td class=""fail"">$osDfsrBackLog</td>"
    }
    else {
        $htmltablerow += "<td class=""pass"">$osDfsrBackLog </td>"
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

