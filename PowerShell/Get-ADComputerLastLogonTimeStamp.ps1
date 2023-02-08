<#
.Synopsis
   Script to get last logon time by computer object
.DESCRIPTION
   Script to get last logon time by computer object from spreadsheet
.REQUIREMENTS
   This script can be run from any domain joined computer
   The column name of the spreadhsheet must be named "DistinguishedName" end each cell must be filled with the computer object DN
   Alternatively, you can use an array of computers. In this case, just remove $computer.DistinguishedName under $ADComputer variable
.AUTHOR
   ref: https://www.netwrix.com/how_to_get_local_group_membership_report.html
.DATE
   09/21/2021
#>

Import-Module ActiveDirectory

$computerLastLogonTimeStamps = @()
$computers = Import-Csv -Path "C:\Temp\file.csv"
#Alternatively, you can use an array of computers, eg: $computers = "LRURDMB9L9ZM2", "LDKCOP921TL33", "LECGYE3N9YYX2", "SRSTAI046751653", "LCNSHGH9QGPN2", "SRSEVE25F2FHKKL", "LBRRDOGT35Y02", "LCATOCGYQ12G2", "LUSYRV7SY76S2", "LCNHUA5N3MP73", "WRUSPFCDLWJD2", "WCNYNGFBZ2GD2", "WUSBURJV1PGK2", "WUKPLYJHFT4W2", "LUSMGI9MJZ173", "LCNHUA8HZ46S2", "lusarkxl90c26", "WKRRGYF939WL2", "LRUSTUJWVL562", "WDEVDN5T34NX2", "WCARGU5S3CTH3", "AZR-ECTESTVM10", "ISXXENSQL02DB", "LPLPOZGZKDPG3", "LMXQROJZ5NS32", "ACCSSPCS", "LINDEL3G5M5S2", "ACCSSPSS-SOFS", "LRUISSHDW0MQ2", "LRUMSW69BQ2Z2", "LMXDTS3R706S2", "LCARGUCHGFV93", "LMXDTSC5YJMQ2", "AZR-WEWCLU029", "LRUMOW7GZB9Y2", "ISXXENSQL02CLU", "LUSNWK579Z473", "ISC-TEST-HA01", "WMXTOT5YJMRD2", "ACCSSPSS", "LCLSGOHXL2L72", "LITRCMFK8LQ13", "YRVGUMMISC-VM", "LCNHUA415PFH2", "AZR-EUS2WCLU054", "LRUMOS8V136H2", "LNLVEGFDS1TT2", "SRSRNI27H011K5Y", "ACCSSPCS-SOFS", "LMXDTS49RQ1Z2", "LARBUE7CQ1QH2", "LRUISS18LTLH2", "lcnchuza71t78"

foreach ($computer in $computers) {
   $ADComputer = Get-ADComputer -Identity $computer.DistinguishedName -Properties * | Select-Object Name, LastLogonTimeStamp, OperatingSystem
   $computerLastLogonTimeStamps += New-Object PsObject -Property @{
      Name               = $ADComputer.Name
      LastLogonTimeStamp = w32tm.exe /ntte $ADComputer.LastLogonTimeStamp
      OperatingSystem    = $ADComputer.OperatingSystem
   }
}

$computerLastLogonTimeStamps | Export-Csv -Path "C:\Temp\computers.csv" -NoTypeInformation
