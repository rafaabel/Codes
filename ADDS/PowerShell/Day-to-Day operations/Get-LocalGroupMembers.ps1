<#
.Synopsis
   Script to get all users by local group
.DESCRIPTION
   Script to get all users by local group. There is no members in the group, it is not listed in this script
.REQUIREMENTS
   This script can be run from any domain joined computer
.AUTHOR
   ref: https://www.netwrix.com/how_to_get_local_group_membership_report.html
.DATE
   09/21/2021
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