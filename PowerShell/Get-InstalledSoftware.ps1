<#
.SYNOPSIS
Gets the installed applications on a local or remote computer.

.DESCRIPTION
Returns information about all installed applications for a computer, not just those installed by Windows Installer.

Without parameters, the script gets the installed applications on the local computer and includes errors at the end of the output.

.PARAMETER ComputerName
Gets the installed applications for the specified computers. The default is the local computer.

Type the NetBIOS name, an IP address, or a fully qualified domain name of a computer or you can pass an array of strings to the script that represent computer names.

.PARAMETER HideErrors
Removes errors from the output. Any errors thrown are ignored and are not passed as output. If this switch is set, the user should re-run the script and set the ShowErrors switch to ensure valid results.

.PARAMETER ShowErrors
Shows only errors (if any were encountered) as output. Output is returned as a hashtable. No valid results are shown if this switch is set, only errors.

.INPUTS
Values for ComputerName may be passed into the script through the pipeline.

.EXAMPLE
PS C:\> .\getInstalledSoftware.ps1

Gets the installed applications on the localhost.

.EXAMPLE
PS C:\> .\getInstalledSoftware.ps1 -ComputerName SVR001, SVR002, SVR003

Gets the installed applications on SVR001, SVR002, SVR003 and displays any errors encountered.

.EXAMPLE
PS C:\> $names = Get-Content C:\ListOfNames.txt
PS C:\> $names | .\getInstalledSoftware.ps1 -ShowErrors
PS C:\> $names | .\getInstalledSoftware.ps1 -HideErrors

Attempts to get installed applications from all computers in ListOfNames.txt but only dispays errors that were encountered. This is useful for verifying results from the next command, especially when ListOfNames contains a large number of computers. 

The next command gets the installed applications on the computers in C:\ListOfNames.txt but does not include any error information.
#>

#*=============================================================================
#* Name:	getInstalledSoftware
#* Created: 12/9/2011
#* Author: 	James Keeler
#* Email: 	James.R.Keeler(at)gmail.com
#*
#* Params:	[String[]] $ComputerName - name(s) of the remote computer(s)
#*			[Switch] $HideErrors - do not show errors in output
#*			[Switch] $ShowErrors - show only errors in output
#* Returns:	All installed software for the computer(s)
#*-----------------------------------------------------------------------------
#* Purpose:	Quickly returns information about all installed software on
#* computers regardless of whether it was installed by Windows Installer.
#*
#*=============================================================================

#*=============================================================================
#* REVISION HISTORY
#*-----------------------------------------------------------------------------
#* Version:		1.1
#* Date: 		12/12/2011
#* Time: 		4:28 PM
#* Issue: 		Install date not properly formatted
#* Solution:	Use substring to re-format the string
#*
#*-----------------------------------------------------------------------------
#* Version:		1.2
#* Date: 		12/19/2011
#* Time: 		10:55 AM
#* Issue: 		No data returned for 64-bit apps
#* Solution:	Check for 64-bit OS, then enumerate the Wow6432Node key
#*
#*-----------------------------------------------------------------------------
#* Version:		1.3
#* Date: 		12/28/2011
#* Time: 		10:47 AM
#* Issue: 		No options for error output
#* Solution:	Added switch parameters to either show or hide errors
#*
#*=============================================================================

#*=============================================================================
#* SCRIPT BODY
#*=============================================================================
function Get-InstalledSoftware {
    param 
    ( 
        [Parameter(ValueFromPipeline = $true)] 
        [String[]] $ComputerName = @($env:COMPUTERNAME),
        [switch] $HideErrors,
        [switch] $ShowErrors
    ) 
 
    begin { 
        # Create an array to hold our job objects 
        $jobs = @() 
	
        # Ensure that both switches weren't set
        if ($ShowErrors -and $HideErrors) { throw "Invalid switch parameter combination" }
    } 
 
    process { 
        foreach ($name in $ComputerName) { 
            # We use Invoke-Command to remotely call the scriptblock below and  
            # create a job for each computer so that the work runs concurrently. 
            $jobs += Invoke-Command -ComputerName $name -ScriptBlock `
            { 
		
                #*=============================================================================
                #* BEGIN REMOTE SCRIPTBLOCK
                #*=============================================================================

                # Any error at this point should be terminating
                $ErrorActionPreference = "Stop"
		
                # Create a custom object to hold our application information 
                Add-Type @' 
public class InstalledApplication { 
    public string     DisplayName; 
    public string     InstallDate; 
    public string     Publisher; 
    public string     DisplayVersion; 
    public int        VersionMajor; 
    public int         VersionMinor; 
    public double     EstimatedSizeMB; 
    public string     ModifyPath; 
    public string     InstallSource;
    public string     UninstallString; 
} 
'@ # This is required to be at the beginning of the line 
 
                # This is the real magic of the script.  We use Get-ChildItem to  
                # get all of the subkeys that contain application info. 
                $keys = Get-ChildItem `
                    HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -Recurse 

                # Get registry info from the Wow6432Node if the computer is 64-bit
                if ((Get-WmiObject Win32_ComputerSystem).SystemType -like "x64*") {
                    $keys += Get-ChildItem `
                        HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -Recurse
                }

                $app = New-Object InstalledApplication 
 
                # Build out each InstalledApplication object 
                foreach ($key in $keys) { 
                    # If we've made it to this point we can safely ignore errors
                    $ErrorActionPreference = "SilentlyContinue"
	
                    $app.DisplayName = $key.GetValue("DisplayName") 
                    if ([string]::IsNullOrEmpty($app.DisplayName)) { continue }  

                    # We need to convert the date from yyyymmdd to mm/dd/yyyy 
                    if ($tempDate = $key.GetValue("InstallDate")) { 
                        $tempDate = $tempDate.SubString(4, 2) + "/" + `
                            $tempDate.SubString(6, 2) + "/" + `
                            $tempDate.SubString(0, 4) 
                    } 
     
                    $app.InstallDate = $tempDate 
                    $app.Publisher = $key.GetValue("Publisher") 
                    $app.DisplayVersion = $key.GetValue("DisplayVersion") 
                    $app.VersionMajor = $key.GetValue("VersionMajor") 
                    $app.VersionMinor = $key.GetValue("VersionMinor") 
                    $app.EstimatedSizeMB = '{0:N2}' -f ($key.GetValue("EstimatedSize") / 1MB) 
                    $app.ModifyPath = $key.GetValue("ModifyPath") 
                    $app.InstallSource = $key.GetValue("Installsource") 
                    $app.UninstallString = $key.GetValue("UninstallString") 
	
                    # Only send back data for apps with a name
                    if ($app.DisplayName) { Write-Output $app }
	
                    $ErrorActionPreference = "Continue"
                } # end foreach key 

                #*=============================================================================
                #* END REMOTE SCRIPTBLOCK
                #*=============================================================================
			
            } -AsJob
        } # end foreach name 
    } 

    # Wait for all jobs to complete, receive output, then remove the jobs
    end { 
        $originalColor = $Host.UI.RawUI.ForegroundColor 
        $errorList = @{}
        $jobs | Wait-Job | Out-Null
	
        # Completed successfully
        $completed = $jobs | where { $_.State -eq "Completed" } | Receive-Job
	
        # Did not complete
        $jobs | where { $_.State -ne "Completed" } | `
            foreach { $errorList[$_.Location] = Receive-Job -Job $_ 2>&1 }
	
        # Display the appropriate output based on the switch parameters
        if ($HideErrors) {
            Write-Output $completed
        }
        elseif ($ShowErrors) {
            # Since these are errors, they need to be displayed in red text
            $Host.ui.rawui.ForegroundColor = "red" 
            Write-Output $errorList
            $Host.ui.rawui.ForegroundColor = $originalColor 
        }
        else {
            Write-Output $completed
            $Host.ui.rawui.ForegroundColor = "red" 
            Write-Output $errorList
            $Host.ui.rawui.ForegroundColor = $originalColor 
        }
	
        $jobs | Remove-Job 
    }
    #*=============================================================================
    #* END OF SCRIPT: getInstalledSoftware
    #*=============================================================================
}


$dt = [datetime]::now
$dmy = "$($dt.Day).$($dt.Month).$($dt.Year)"
$outFile = "F:\A\Inventory\DC-installed-software-($($dmy)).csv"

##$adcs1 = Get-ADDomainController -Filter * | sort isReadOnly, name
$aarr = Get-ADDomainController -Filter * | sort isReadOnly, name | select -ExpandProperty name
###$aarr = Get-ADDomainController azr-eus2w6707 | sort isReadOnly, name | select -ExpandProperty name
#$adcs1 = Get-ADDomainController -Filter 'isreadonly -eq $false'| select isreadonly, name | sort name
##[string[]]$aarr=$adcs1.GetEnumerator().ForEach({ "$($_.Name)$($_.Value)" })

$hOutcome = @()
#foreach ($dc in $adcs) {
    
#   $dc.name

#  $asoft = $null
$hOutcome = Get-InstalledSoftware -ComputerName $aarr  | select psComputerName, displayName, publisher, displayVersion, installDate, installSource, uninstallString | sort psComputerName, displayName 
            

# $hOutcome += $asoft
#}

$hOutcome | Out-GridView 
$hOutcome | Export-Csv $outFile -NoTypeInformation


#Get-InstalledSoftware -ComputerName "ftnw4100" | Sort-Object DisplayName | ft DisplayName, DisplayVersion, Publisher, InstallDate -AutoSize
