<#
.SYNOPSIS
    Reports local group membership on a computer, including nested domain accounts.

.DESCRIPTION
    Uses ADSI to enumerate every local group on the target computer and lists its
    members, distinguishing between local and domain accounts. Empty groups (with
    no members) are not included in the output. Results are exported to a
    semicolon-delimited, UTF-8 CSV file named after the computer and timestamp.

.NOTES
    Author       : ref: https://www.netwrix.com/how_to_get_local_group_membership_report.html
    Date         : 09/21/2021
    Requirements : This script can be run from any domain joined computer
#>


$strComputer = Get-Content env:computername #Enter the name of the target computer, localhost is used by default
Write-Host "Computer: $strComputer"
$computer = [ADSI]"WinNT://$strComputer"
$objCount = ($computer.psbase.children | Measure-Object).count
Write-Host "Q-ty objects for computer '$strComputer' = $objCount"
$counter = 1
$result = @()
foreach ($adsiObj in $computer.psbase.children) {
    switch -regex($adsiObj.psbase.SchemaClassName) {
        "group" {
            $group = $adsiObj.name
            $localGroup = [ADSI]"WinNT://$strComputer/$group,group"
            $members = @($localGroup.psbase.Invoke("members"))
            $objCount = ($members | Measure-Object).count
            Write-Host "Q-ty objects for group '$group' = $objCount"
            $gName = $group.tostring()

            foreach ($member in $members) {
                $name = $member.GetType().InvokeMember("Name", "GetProperty", $Null, $member, $Null)
                $path = $member.GetType().InvokeMember("ADsPath", "GetProperty", $Null, $member, $Null)
                Write-Host " Object = $path"

                $isGroup = ($member.GetType().InvokeMember("Class", "GetProperty", $Null, $member, $Null) -eq "group")
                if (($path -like "*/$strComputer/*") -Or ($path -like "WinNT://NT*")) {
                    $type = "Local"
                }
                else { $type = "Domain" }
                $result += New-Object PSObject -Property @{
                    Computername  = $strComputer
                    NameMember    = $name
                    PathMember    = $path
                    TypeMember    = $type
                    ParentGroup   = $gName
                    isGroupMember = $isGroup
                    Depth         = $counter
                }
            }
        }
    } #end switch
} #end foreach
Write-Host "Total objects = " ($result | Measure-Object).count
$result = $result | Select-Object Computername, ParentGroup, NameMember, TypeMemeber, PathMember, isGroupMemeber, Depth
$result | Export-Csv -path ("C:\Temp\localGroups({0})-{1:yyyyMMddHHmm}.csv" -f
    $env:COMPUTERNAME, (Get-Date)) -Delimiter ";" -Encoding "UTF8" -Force -NoTypeInformation