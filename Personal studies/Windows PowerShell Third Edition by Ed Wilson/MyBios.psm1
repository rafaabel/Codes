
function Get-MyBios {
    <#
.Synopsis
   Get bios information from local or remote computer
.DESCRIPTION
  This function gets bios information from local or remote computer
.EXAMPLE
   Get-MyBios
   Gets bios information from local computer
.EXAMPLE
   Get-MyBios -cn remoteComputer
   Get bios information from remote named remote computer
#>

    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # name of remote computer
        [alias("cn")]
        [Parameter(
            ValueFromPipeline = $true,
            Position = 0,
            ParameterSetName = "remote")]

        [string]$computername)
      
    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            "remote" { get-ciminstance -classname win32_bios -cn $computername }
            DEFAULT { get-ciminstance  -classname Win32_BIOS }
        }#endswitch

    }
   
}

New-Alias -name gmb -value Get-MyBios
Export-ModuleMember -Function * -Alias *