
<#
.Synopsis
   Detect AdminSDHolder users and groups
.DESCRIPTION
   Detect AdminSDHolder users and groups, clean AdminCount attribute and enable inheritance
.REQUIREMENTS
   This script must be run from any DC
   -Module ActiveDirectory
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
   ref: https://gist.github.com/webash/b34c5a422288827ff4e53318e34c6923
.DATE
   07/11/2022
#>
Import-Module ActiveDirectory
function Get-OrphanAdminSdHolderGroup {
    [CmdletBinding()]	
    param ()
    begin {}
    process {}
    end { 
        Get-ADGroup -LDAPFilter '(&(objectClass=group)(AdminCount=1) (!(|(cn=Administrators)(cn=Enterprise Admins)(cn=Domain Admins)(cn=Backup Operators)(cn=Server Operators)(cn=Replicator)(cn=Account Operators)(cn=Domain Controllers)(cn=Read-only Domain Controllers)(cn=Schema Admins)(cn=Print Operators)(cn=Key Admins)(cn=Enterprise Key Admins))))'
    }
}
<#
    .Synopsis
        Detects Orphaned SD Admin groups
    .DESCRIPTION
        Get all groups tthat have the AD Attribute AdminCount=1 set but are not the default protected groups. If the group has the AdminCount=1 enabled but is 
        not a protected group then the group is considered an orphaned admin group.
#>
function Clear-OrphanAdminSdHolderGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [Microsoft.ActiveDirectory.Management.ADPrincipal[]]$OrphanGroup
    )
    begin {}
    process {
        $OrphanGroup |
        Where-Object { $_.SamAccountName -ne 'krbtgt' } |
        ForEach-Object {
            $group = $_
            if ($pscmdlet.ShouldProcess($_, 'Clear AdminCount and reset permissions inheritance')) {
                try {
                    $group  | Set-ADGroup -Clear AdminCount -ErrorAction Stop
                    Write-Verbose -Message ('Clearing AdminCount for {0}' -f $group.SamAccountName)
                }
                catch {
                    Write-Warning -Message "Failed to clear admincount property for $($group.SamAccountName) because $($_.Exception.Message)"
                }
		
                try {
                    $Acl = Get-ACL -Path ('AD:\{0}' -f $group.DistinguishedName) -ErrorAction Stop
                    If ($Acl.AreAccessRulesProtected) {
                        $Acl.SetAccessRuleProtection($False, $True)
                        Set-ACL -AclObject $ACL -Path ('AD:\{0}' -f $group.DistinguishedName) -ErrorAction Stop
                        Write-Verbose -Message ('Enabling Inheritence for {0}' -f $group.SamAccountName)
                    }
                    else {
                        Write-Verbose -Message ('Inheritence already set for {0}' -f $group.SamAccountName)
                    }
                }
                catch {
                    Write-Warning -Message "Failed to enable inheritence for $($group.SamAccountName) because $($_.Exception.Message)"
                }
            }
        }
    }
    end {}
    <#
    .Synopsis
        Resets admin count attribute and enables inheritable permissions on AD group
    .DESCRIPTION
        The AdminCount attributed is cleared and inheritable permissions are reset
    .PARAMETER OrphanGroup
        A list or array of ADGroup objects
    .EXAMPLE
        Get-OrphanAdminSdHolderGroup| Select -First 1 | Clear-OrphanAdminSdHolderGroup -WhatIf
    .EXAMPLE
        Get-OrphanAdminSdHolderGroup | Clear-OrphanAdminSdHolderGroup
#>
}  
function Get-OrphanAdminSdHolderUser {
    [CmdletBinding()]	
    param()
    begin {}
    process {
    }
    end {	
        $UsersInAdminGroups = (Get-ADGroup -LDAPFilter '(adminCount=1)') | 
        ForEach-Object {
            # Get all users from all admin groups recursively
            Get-ADGroupMember $_ -Recursive | Where-Object { $_.ObjectClass -eq 'User' }
            # ...then sort them by distinguishedName to ensure accurate -Unique results (because some users might be in multiple protected groups)
        }  | Sort-Object distinguishedname | Select-Object -Unique

        #Get List of Admin Users (Past and Present) = $UsersFlaggedAsAdmin
        #Compare $UsersFlaggedAsAdmin to $Admins and place in appropriate hash table
        Get-ADUser -LDAPFilter '(adminCount=1)' |
        ForEach-Object {
            If ($_.samAccountName -notin $UsersInAdminGroups.samAccountName) {
                Write-Verbose -Message ("ORPHAN`t`t{0}" -f $_.samAccountName)
                $_
            }
            else {
                Write-Verbose -Message ("STILL ADMIN`t{0}" -f $_.samAccountName)
            }
        }
    }
    <#
    .Synopsis
        Detects Orphaned SD Admin users
    .DESCRIPTION
        Get all users that are members of protected groups within AD and compares membership with users
        that have the AD Attribute AdminCount=1 set. If the user has the AdminCount=1 enabled but is 
        not a member of a protected group then the user is considered an orphaned admin user.
#>
}

function Clear-OrphanAdminSdHolderUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [Microsoft.ActiveDirectory.Management.ADPrincipal[]]$OrphanUser
    )
    begin {}
    process {
        $OrphanUser |
        Where-Object { $_.SamAccountName -ne 'krbtgt' } |
        ForEach-Object {
            $user = $_
            if ($pscmdlet.ShouldProcess($_, 'Clear AdminCount and reset permissions inheritance')) {
                try {
                    $user | Set-ADUser -Clear AdminCount -ErrorAction Stop
                    Write-Verbose -Message ('Clearing AdminCount for {0}' -f $user.SamAccountName)
                }
                catch {
                    Write-Warning -Message "Failed to clear admincount property for $($user.SamAccountName) because $($_.Exception.Message)"
                }
		
                try {
                    $Acl = Get-ACL -Path ('AD:\{0}' -f $user.DistinguishedName) -ErrorAction Stop
                    If ($Acl.AreAccessRulesProtected) {
                        $Acl.SetAccessRuleProtection($False, $True)
                        Set-ACL -AclObject $ACL -Path ('AD:\{0}' -f $user.DistinguishedName) -ErrorAction Stop
                        Write-Verbose -Message ('Enabling Inheritence for {0}' -f $user.SamAccountName)
                    }
                    else {
                        Write-Verbose -Message ('Inheritence already set for {0}' -f $user.SamAccountName)
                    }
                }
                catch {
                    Write-Warning -Message "Failed to enable inheritence for $($user.SamAccountName) because $($_.Exception.Message)"
                }
            }
        }
    }
    end {}
    <#
    .Synopsis
        Resets admin count attribute and enables inheritable permissions on AD user
    .DESCRIPTION
        The AdminCount attributed is cleared and inheritable permissions are reset
    .PARAMETER OrphanUser
        A list or array of ADUser objects
    .EXAMPLE
        Get-OrphanAdminSdHolderUser| Select -First 1 | Clear-OrphanAdminSdHolderUser -WhatIf
    .EXAMPLE
        Get-OrphanAdminSdHolderUser | Clear-OrphanAdminSdHolderUser
#>
}

Get-OrphanAdminSdHolderGroup | Clear-OrphanAdminSdHolderGroup
Get-OrphanAdminSdHolderUser | Clear-OrphanAdminSdHolderUser
