
<#
.Synopsis
   Script to find out all the delegations in Active Directory
.DESCRIPTION
   You can extract an overview of your delegation and maybe identify some clean-up candidates. A .txt file is generated in the user`s desktop. 
   Finally, you rename the file to .csv and open in Excel as ";" delimited
.REQUIREMENTS
   This script must be run from any DC
.AUTHOR
   ref: https://www.easy365manager.com/how-to-document-ou-delegation/
.DATE
   09/09/2021
#>

# Set up output file
$File = "C:\Temp\file.txt"
"Path;ID;Rights;Type" | Out-File $File
# Import AD module
Import-Module ActiveDirectory
# Get all OU's in the domain
$OUs = Get-ADOrganizationalUnit -Filter *
$Result = @()
ForEach ($OU In $OUs) {
    # Get ACL of OU
    $Path = "AD:\" + $OU.DistinguishedName
    $ACLs = (Get-Acl -Path $Path).Access
    ForEach ($ACL in $ACLs) {
        # Only examine non-inherited ACL's
        If ($ACL.IsInherited -eq $False) {
            # Objectify the result for easier handling
            $Properties = @{
                ACL = $ACL
                OU  = $OU.DistinguishedName
            }
            $Result += New-Object psobject -Property $Properties
        }
    }
}
ForEach ($Item In $Result) {
    $Output = $Item.OU + ";" + $Item.ACL.IdentityReference + ";" + $Item.ACL.ActiveDirectoryRights + ";" + $Item.ACL.AccessControlType
    $Output | Out-File $File -Append
    Write-Host $Output
}