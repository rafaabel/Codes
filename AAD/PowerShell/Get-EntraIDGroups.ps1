<#
.SYNOPSIS
    Exports Entra ID cloud-only group details for reporting and auditing.

.DESCRIPTION
    Connects to Microsoft Graph and retrieves all groups that are not synchronized
    from on-premises Active Directory. For each cloud-only group, resolves its owners,
    source (Microsoft 365 Group, Security Group, or Other), membership type
    (Assigned/Dynamic), Teams enablement, role assignment eligibility, and expiration
    details. The consolidated report is exported to EntraIDGroups.csv.

.NOTES
    Author       : Rafael Abel - rgonca10@ext.uber.com
    Date         : 09/15/2025
    Requirements : Microsoft Graph PowerShell SDK
                   https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0
#>


# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Group.Read.All","Directory.Read.All"
x
# Get only cloud-only groups (exclude Windows AD synced)
$groups = Get-MgGroup -All -Property "id,displayName,groupTypes,securityEnabled,mail,createdDateTime,expirationDateTime,resourceProvisioningOptions,membershipRuleProcessingState,membershipType,onPremisesSyncEnabled" `
         | Where-Object { $_.OnPremisesSyncEnabled -ne $true }

# Build the report
$report = foreach ($g in $groups) {

    # Owners
    $owners = (Get-MgGroupOwner -GroupId $g.Id -All -ErrorAction SilentlyContinue | ForEach-Object {
    switch ($_.ODataType) {
        "#microsoft.graph.user"              { $_.UserPrincipalName }
        "#microsoft.graph.servicePrincipal"  { $_.AppId }           # or DisplayName
        "#microsoft.graph.group"             { $_.DisplayName }
        default                              { $_.Id }
    }
}) -join "; "
    # Source
    if ($g.GroupTypes -contains "Unified") {
        $source = "Microsoft 365 Group"
    } elseif ($g.SecurityEnabled -eq $true) {
        $source = "Security Group"
    } else {
        $source = "Other"
    }

    # Teams enabled
    $teamsEnabled = if ($g.ResourceProvisioningOptions -contains "Team") { $true } else { $false }

    # Role assignments allowed
    $roleAssignmentsAllowed = if ($g.SecurityEnabled -eq $true) { "Yes" } else { "No" }

    # Membership type
    $membershipType = if ($g.GroupTypes -contains "DynamicMembership") { "Dynamic" } else { "Assigned" }

    [PSCustomObject]@{
        Name                       = $g.DisplayName
        ObjectId                   = $g.Id
        'Group type'               = ($g.GroupTypes -join ", ")
        'Membership type'          = $membershipType
        Email                      = $g.Mail
        Source                     = $source
        Owners                     = $owners
        'Role assignments allowed' = $roleAssignmentsAllowed
        'Security enabled'         = $g.SecurityEnabled
        'Teams enabled'            = $teamsEnabled
        'Expires at'               = $g.ExpirationDateTime
        'Created at'               = $g.CreatedDateTime
        'Processing status'        = $g.MembershipRuleProcessingState
    }
}

# Export to CSV
$report | Export-Csv -Path ".\EntraIDGroups.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Report generated: EntraIDGroups.csv"
