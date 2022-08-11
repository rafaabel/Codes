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

$strComputer = get-content env:computername #Enter the name of the target computer, localhost is used by default
Write-Host "Computer: $strComputer"
$computer = [ADSI]"WinNT://$strComputer"
$objCount = ($computer.psbase.children | measure-object).count
Write-Host "Q-ty objects for computer '$strComputer' = $objCount"
$Counter = 1
$result = @()
foreach ($adsiObj in $computer.psbase.children) {
    switch -regex($adsiObj.psbase.SchemaClassName) {
        "group" {
            $group = $adsiObj.name
            $LocalGroup = [ADSI]"WinNT://$strComputer/$group,group"
            $Members = @($LocalGroup.psbase.Invoke("Members"))
            $objCount = ($Members | measure-object).count
            Write-Host "Q-ty objects for group '$group' = $objCount"
            $GName = $group.tostring()

            ForEach ($Member In $Members) {
                $Name = $Member.GetType().InvokeMember("Name", "GetProperty", $Null, $Member, $Null)
                $Path = $Member.GetType().InvokeMember("ADsPath", "GetProperty", $Null, $Member, $Null)
                Write-Host " Object = $Path"

                $isGroup = ($Member.GetType().InvokeMember("Class", "GetProperty", $Null, $Member, $Null) -eq "group")
                If (($Path -like "*/$strComputer/*") -Or ($Path -like "WinNT://NT*")) {
                    $Type = "Local"
                }
                Else { $Type = "Domain" }
                $result += New-Object PSObject -Property @{
                    Computername  = $strComputer
                    NameMember    = $Name
                    PathMember    = $Path
                    TypeMember    = $Type
                    ParentGroup   = $GName
                    isGroupMember = $isGroup
                    Depth         = $Counter
                }
            }
        }
    } #end switch
} #end foreach
Write-Host "Total objects = " ($result | measure-object).count
$result = $result | select-object Computername, ParentGroup, NameMember, TypeMemeber, PathMember, isGroupMemeber, Depth
$result | Export-Csv -path ("C:\temp\LocalGroups({0})-{1:yyyyMMddHHmm}.csv" -f
    $env:COMPUTERNAME, (Get-Date)) -Delimiter ";" -Encoding "UTF8" -force -NoTypeInformation