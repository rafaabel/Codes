param (
    $OutputFile
)

#Known domain SIDs:
<#
Mars-AD / Mars-AD.Net: S-1-5-21-3555285318-3598121220-927574299
RCAD / RCAD.NET: S-1-5-21-2208061335-1053785876-3506434438
DPC / dpc.com: S-1-5-21-1177238915-790525478-725345543
CORP / corp.mars: S-1-5-21-3260676326-1440802575-504967488
MARSDOM / marsdom.msds.mars: S-1-5-21-1703689357-163518943-837300805
MMI / mmi.local: S-1-5-21-343818398-1004336348-725345543
MTODOM01 / mtodom01.corp.mars: S-1-5-21-2071871815-217475110-1267956476
EUROPE / europe.corp.mars: S-1-5-21-1258371818-444928156-1722840164
WWY / wwy.wrigley.net: S-1-5-21-3290484597-3751910110-3978201916
MARSUX / marsux.net: S-1-5-21-114928828-3254496981-2624781105

AM / am.mfg.mars: S-1-5-21-832990446-3945610031-3603561387
IAMSCTRL / iamsctrl.com: S-1-5-21-1667831118-2708761547-2400660538
EU / eu.mfg.mars: S-1-5-21-1162813107-2366814082-2215518936
DF-MARS / df-mars.net: S-1-5-21-3676301590-1045312228-1300451359
MSSIT / mssit.net: S-1-5-21-3323189917-740861215-3314737820
IDSSKL / idsskl.net: S-1-5-21-2327563345-1759895495-1562864870
#>

$domainSIDs = @{
    "S-1-5-21-2208061335-1053785876-3506434438" = "RCAD.NET"
    "S-1-5-21-1177238915-790525478-725345543"   = "dpc.com"
    "S-1-5-21-3260676326-1440802575-504967488"  = "corp.mars"
    "S-1-5-21-3290484597-3751910110-3978201916" = "wwy.wrigley.net"
    "S-1-5-21-1703689357-163518943-837300805"   = "marsdom.msds.mars"
    "S-1-5-21-343818398-1004336348-725345543"   = "mmi.local"
    "S-1-5-21-2071871815-217475110-1267956476"  = "mtodom01.corp.mars"
    "S-1-5-21-1258371818-444928156-1722840164"  = "europe.corp.mars"
    "S-1-5-21-832990446-3945610031-3603561387"  = "am.mfg.mars"
    "S-1-5-21-1667831118-2708761547-2400660538" = "iamsctrl.com"
    "S-1-5-21-1162813107-2366814082-2215518936" = "eu.mfg.mars"
    "S-1-5-21-3676301590-1045312228-1300451359" = "df-mars.net"
    "S-1-5-21-3323189917-740861215-3314737820"  = "mssit.net"
}
$pdc = "azr-eus2w6700"
if ($PSBoundParameters -notcontains "OutputFile") {
    $today = Get-Date -Format "yyyyMMdd"
    $OutputFile = "C:\Support\C\SIDHistory Cleanup\SIDHistory - $today`.csv"
}

$userList = Get-ADUser -Filter "sIDHistory -like '*'" -Properties DisplayName, mail, Title, Description, SIDHistory, whenCreated, CanonicalName, extensionAttribute14
$total = $userList.Count
$ptr = 0
"sIDHistory (users): $total"

foreach ($i in $userList) {
    $ptr++
    Write-Host -ForegroundColor Cyan "`r[$ptr/$total] Process user $($i.CanonicalName)...$([char]27)[0K" -NoNewline
    foreach ($ii in $i.SIDHistory) {
        [PSCustomObject]@{
            SamAccountName            = $i.samAccountName
            DisplayName               = $i.displayName    
            WhenCreated               = $i.whenCreated
            AccountDomainName         = $domainSIDs[$ii.accountDomainSid.ToString()]
            AccountDomainSid          = $ii.accountDomainSid
            SIDHistory                = $ii.Value
            LastOriginatingChangeTime = ($i | Get-ADReplicationAttributeMetadata -Properties sIDHistory -Server $pdc).LastOriginatingChangeTime
            Enabled                   = $i.enabled
            CanonicalName             = $i.canonicalName
            Type                      = $i.extensionAttribute14
            Title                     = $i.Title
            Description               = $i.Description
        } | Export-Csv $outputFile -NoTypeInformation -Encoding utf8 -Append 
    }
}