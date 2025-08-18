
<#
.Synopsis
   Get CA policies details from Entra ID
.DESCRIPTION
   Get CA policies details from Entra ID
.REQUIREMENTS
   Microsoft Graph PowerShell SDK: https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0
   Rafael Abel - rgonca10@ext.uber.com
.DATE
   08/15/2025
#>

Import-Module Microsoft.Graph.Identity.SignIns
Import-Module Microsoft.Graph.Applications
Import-Module Microsoft.Graph.Users

Connect-MgGraph -Scopes "Policy.Read.All","Directory.Read.All"

function Resolve-Objects {
    param($ids)
    $names = @()
    foreach ($id in $ids) {
        switch ($id) {
            "All"                   { $names += "All Users" }
            "None"                  { $names += "None" }
            "GuestsOrExternalUsers" { $names += "Guests or External Users" }
            "AllGuests"             { $names += "All Guests" }
            "AllUsers"              { $names += "All Users" }
            default {
                if ($id -match "^[0-9a-fA-F-]{36}$") {
                    $user = Get-MgUser -UserId $id -Property DisplayName -ErrorAction SilentlyContinue
                    if ($user) { $names += $user.DisplayName; continue }

                    $group = Get-MgGroup -GroupId $id -Property DisplayName -ErrorAction SilentlyContinue
                    if ($group) { $names += $group.DisplayName; continue }

                    $names += $id
                } else { $names += $id }
            }
        }
    }
    return ($names -join "; ")
}

function Resolve-Roles {
    param($ids)
    $roleNames = @()
    foreach ($id in $ids) {
        $role = $rolesActive | Where-Object { $_.Id -eq $id }
        if ($role) { $roleNames += $role.DisplayName; continue }

        $roleTemplate = $rolesTemplate | Where-Object { $_.Id -eq $id }
        if ($roleTemplate) { $roleNames += $roleTemplate.DisplayName; continue }

        $roleNames += $id
    }
    return ($roleNames -join "; ")
}

function Resolve-Apps($ids) {
    if (-not $ids) { return $null }

    # Well-known Microsoft app IDs
    $knownApps = @{
        "797f4846-ba00-4fd7-ba43-dac1f8f63013" = "Windows Azure Service Management API"
        "00000002-0000-0ff1-ce00-000000000000" = "Microsoft Graph"
        "00000003-0000-0000-c000-000000000000" = "Office 365 SharePoint Online"
        "00000002-0000-0ff1-0000-000000000000" = "Exchange Online"
        "00000007-0000-0000-c000-000000000000" = "Microsoft Teams"
    }

    $names = foreach ($id in $ids) {
        if ($id -in @("All", "None", "Office365", "MicrosoftAdminPortals")) {
            $id
        }
        elseif ($knownApps.ContainsKey($id)) {
            $knownApps[$id]
        }
        else {
            try {
                (Get-MgServicePrincipal -ServicePrincipalId $id).DisplayName
            }
            catch { $id }
        }
    }

    $names -join "; "
}

function Resolve-Locations($ids) {
    if (-not $ids) { return $null }
    $names = foreach ($id in $ids) {
        # If it's a GUID, try to resolve
        if ($id -match '^[0-9a-fA-F-]{36}$') {
            try { 
                (Get-MgIdentityConditionalAccessNamedLocation -NamedLocationId $id).DisplayName 
            }
            catch { $id } # fallback raw
        }
        else {
            # keywords like All, None, AllTrusted, Selected
            $id
        }
    }
    $names -join "; "
}

# --- Get all CA policies ---
$policies = Get-MgIdentityConditionalAccessPolicy
$results = @()

foreach ($p in $policies) {
    $obj = [ordered]@{
        PolicyName                        = $p.DisplayName
        Description                       = $p.Description
        CreationTime                      = $p.CreatedDateTime
        ModifiedTime                      = $p.ModifiedDateTime
        State                             = $p.State

        IncludeUsers                      = Resolve-Objects $p.Conditions.Users.IncludeUsers
        ExcludeUsers                      = Resolve-Objects $p.Conditions.Users.ExcludeUsers
        IncludeGroups                     = Resolve-Objects $p.Conditions.Users.IncludeGroups
        ExcludeGroups                     = Resolve-Objects $p.Conditions.Users.ExcludeGroups
        IncludeRoles                      = Resolve-Roles $p.Conditions.Users.IncludeRoles
        ExcludeRoles                      = Resolve-Roles $p.Conditions.Users.ExcludeRoles
        IncludeGuestOrExternalUsers       = $p.Conditions.Users.IncludeGuestsOrExternalUsers.GuestOrExternalUserTypes
        ExcludeGuestOrExternalUsers       = $p.Conditions.Users.ExcludeGuestsOrExternalUsers.GuestOrExternalUserTypes
        IncludeApplications               = Resolve-Apps $p.Conditions.Applications.IncludeApplications
        ExcludeApplications               = Resolve-Apps $p.Conditions.Applications.ExcludeApplications

        UserAction                        = ($p.Conditions.UserActions -join "; ")
        UserRisk                          = ($p.Conditions.UserRiskLevels -join "; ")
        SigninRisk                        = ($p.Conditions.SignInRiskLevels -join "; ")

        ClientApps                        = ($p.Conditions.ClientAppTypes -join "; ")
        IncludeDevicePlatform             = ($p.Conditions.Platforms.IncludePlatforms -join "; ")
        ExcludeDevicePlatform             = ($p.Conditions.Platforms.ExcludePlatforms -join "; ")

        IncludeLocations                  = Resolve-Locations $p.Conditions.Locations.IncludeLocations
        ExcludeLocations                  = Resolve-Locations $p.Conditions.Locations.ExcludeLocations

        AccessControl                     = ($p.GrantControls.BuiltInControls -join "; ")
        AccessControlOperator             = $p.GrantControls.Operator
        AuthenticationStrength            = $p.GrantControls.AuthenticationStrength.DisplayName
        AuthenticationStrengthAllowedCombo = ($p.GrantControls.AuthenticationStrength.AllowedCombinations -join "; ")

        AppEnforcedRestrictionEnabled     = $p.SessionControls.AppEnforcedRestrictions.IsEnabled
        CloudAppSecurity                  = $p.SessionControls.CloudAppSecurity.CloudAppSecurityType
        CAEMode                           = $p.SessionControls.ContinuousAccessEvaluationMode
        DisableResilienceDefaults         = $p.SessionControls.DisableResilienceDefaults
        IsSigninFrequencyEnabled          = $p.SessionControls.SignInFrequency.IsEnabled
        SigningFrequencyValue             = $p.SessionControls.SignInFrequency.Value
    }
    $results += [pscustomobject]$obj
}

# --- Pivoted Export ---
$properties = @(
    'Description',
    'CreationTime',
    'ModifiedTime',
    'State',
    'IncludeUsers',
    'ExcludeUsers',
    'IncludeGroups',
    'ExcludeGroups',
    'IncludeRoles',
    'ExcludeRoles',
    'IncludeGuestOrExternalUsers',
    'ExcludeGuestOrExternalUsers',
    'IncludeApplications',
    'ExcludeApplications',
    'UserAction',
    'UserRisk',
    'SigninRisk',
    'ClientApps',
    'IncludeDevicePlatform',
    'ExcludeDevicePlatform',
    'IncludeLocations',
    'ExcludeLocations',
    'AccessControl',
    'AccessControlOperator',
    'AuthenticationStrength',
    'AuthenticationStrengthAllowedCombo',
    'AppEnforcedRestrictionEnabled',
    'CloudAppSecurity',
    'CAEMode',
    'DisableResilienceDefaults',
    'IsSigninFrequencyEnabled',
    'SigningFrequencyValue'
)

$pivotTable = foreach ($prop in $properties) {
    $row = [ordered]@{ Property = $prop }
    foreach ($policy in $results) {
        $row[$policy.PolicyName] = $policy.$prop
    }
    [pscustomobject]$row
}

$pivotTable | Export-Csv -Path ".\CA-Policies.csv" -NoTypeInformation -Encoding UTF8
