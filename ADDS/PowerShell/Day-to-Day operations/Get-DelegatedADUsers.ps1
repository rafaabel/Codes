
<#
.SYNOPSIS
    Documents non-inherited Active Directory OU delegation (ACL) entries.

.DESCRIPTION
    Enumerates every Organizational Unit in the domain and inspects its ACL for
    non-inherited access control entries, writing each finding (OU path, identity,
    rights, and access type) to a semicolon-delimited text file. Rename the output
    file's extension to .csv to open it directly in Excel for delegation review and
    clean-up candidate identification.

.NOTES
    Author       : ref: https://www.easy365manager.com/how-to-document-ou-delegation/
    Date         : 09/09/2021
    Requirements : This script must be run from any DC
#>


# Set up output file
$file = "C:\Temp\file.txt"
"Path;ID;Rights;Type" | Out-File $file
# Import AD module
Import-Module ActiveDirectory
# Get all OU's in the domain
$OUs = Get-ADOrganizationalUnit -Filter *
$result = @()
foreach ($OU In $OUs) {
    # Get ACL of OU
    $Path = "AD:\" + $OU.DistinguishedName
    $ACLs = (Get-Acl -Path $Path).Access
    foreach ($ACL in $ACLs) {
        # Only examine non-inherited ACL's
        If ($ACL.IsInherited -eq $False) {
            # Objectify the result for easier handling
            $Properties = @{
                ACL = $ACL
                OU  = $OU.DistinguishedName
            }
            $result += New-Object psobject -Property $Properties
        }
    }
}
foreach ($item In $result) {
    $output = $Item.OU + ";" + $item.ACL.IdentityReference + ";" + $item.ACL.ActiveDirectoryRights + ";" + $item.ACL.AccessControlType
    $output | Out-File $file -Append
    Write-Host $Output
}