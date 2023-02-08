<#
    .SYNOPSIS
        Get computer password last set time
    .DESCRIPTION
        This function read the local stored computer password last set time, and convert it to a human-readable value.
        This function must be run with SYSTEM account.
    .EXAMPLE
        PS > Get-LocalMachinePasswordLastSet
        ff6301ce 01d80691 = 1/11/2022 13:21:53
    .DATE
        05/08/2022
    #>

#Check current user
if ( (((whoami /user) -split "\n")[-1]) -notmatch "S-1-5-18" ) {
    Write-Host -ForegroundColor Red "You must run PowerShell with SYSTEM(S-1-5-18) account."
    break
}

$keyValue = Get-ItemProperty 'HKLM:\SECURITY\Policy\Secrets\$MACHINE.ACC\CupdTime\'
$HexValue = $keyValue.'(default)' | foreach { 
    ([System.Convert]::ToString($_, 16)).PadLeft(2, '0') 
}
[array]::Reverse($HexValue)

$Arg1 = $HexValue[4..7] -join ""
$Arg2 = $HexValue[0..3] -join ""

    ((nltest /time:$Arg1 $Arg2) -split "\n")[0]