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
# Connect to Graph
Connect-MgGraph -Scopes "Policy.Read.All","Directory.Read.All"

# Cache roles and role templates
$rolesActive   = Get-MgDirectoryRole | Select-Object Id, DisplayName
$rolesTemplate = Get-MgDirectoryRoleTemplate | Select-Object Id, DisplayName

# Cache apps for lookup
$apps = Get-MgServicePrincipal -All | Select-Object Id, DisplayName, AppId

# Cache named locations
$locations = Get-MgIdentityConditionalAccessNamedLocation | Select-Object Id, DisplayName

# --- Helper: Resolve Users/Groups ---
function Resolve-ObjectNames {
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

# --- Helper: Resolve Roles ---
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

# --- Helper: Resolve Apps ---
function Resolve-Apps {
    param($ids)
    $appNames = @()
    foreach ($id in $ids) {
        switch ($id) {
            "All"       { $appNames += "All Apps" }
            "None"      { $appNames += "None" }
            "Office365" { $appNames += "Office 365" }
            default {
                $app = $apps | Where-Object { $_.Id -eq $id }
                if ($app) { $appNames += $app.DisplayName }
                else { $appNames += $id }
            }
        }
    }
    return ($appNames -join "; ")
}

# --- Helper: Resolve Locations ---
function Resolve-Locations {
    param($ids)
    $locNames = @()
    foreach ($id in $ids) {
        switch ($id) {
            "All"  { $locNames += "All Locations" }
            "None" { $locNames += "None" }
            default {
                $loc = $locations | Where-Object { $_.Id -eq $id }
                if ($loc) { $locNames += $loc.DisplayName }
                else { $locNames += $id }
            }
        }
    }
    return ($locNames -join "; ")
}

# --- Get all CA policies ---
$policies = Get-MgIdentityConditionalAccessPolicy -All

$results = @()

foreach ($policy in $policies) {

    # Users / Groups / Roles
    $includeUsers   = Resolve-ObjectNames $policy.Conditions.Users.IncludeUsers
    $excludeUsers   = Resolve-ObjectNames $policy.Conditions.Users.ExcludeUsers
    $includeGroups  = Resolve-ObjectNames $policy.Conditions.Users.IncludeGroups
    $excludeGroups  = Resolve-ObjectNames $policy.Conditions.Users.ExcludeGroups
    $includeRoles   = Resolve-Roles $policy.Conditions.Users.IncludeRoles
    $excludeRoles   = Resolve-Roles $policy.Conditions.Users.ExcludeRoles

    # Target Apps
    $includeApps    = Resolve-Apps $policy.Conditions.Applications.IncludeApplications
    $excludeApps    = Resolve-Apps $policy.Conditions.Applications.ExcludeApplications

    # Named Locations
    $includeLoc     = Resolve-Locations $policy.Conditions.Locations.IncludeLocations
    $excludeLoc     = Resolve-Locations $policy.Conditions.Locations.ExcludeLocations

    # Platforms, Client Apps, Risks
    $platforms      = ($policy.Conditions.Platforms.IncludePlatforms -join "; ")
    $excludePlat    = ($policy.Conditions.Platforms.ExcludePlatforms -join "; ")
    $clientApps     = ($policy.Conditions.ClientAppTypes -join "; ")
    $signInRisk     = ($policy.Conditions.SignInRiskLevels -join "; ")
    $userRisk       = ($policy.Conditions.UserRiskLevels -join "; ")

    # Device filters / states
    $deviceFilters = @()
    if ($policy.Conditions.Devices) {
        if ($policy.Conditions.Devices.IncludeDeviceStates) {
            $deviceFilters += "IncludeDeviceStates: " + ($policy.Conditions.Devices.IncludeDeviceStates -join "; ")
        }
        if ($policy.Conditions.Devices.ExcludeDeviceStates) {
            $deviceFilters += "ExcludeDeviceStates: " + ($policy.Conditions.Devices.ExcludeDeviceStates -join "; ")
        }
        if ($policy.Conditions.Devices.DeviceFilter) {
            $deviceFilters += "DeviceFilter: " + ($policy.Conditions.Devices.DeviceFilter | ConvertTo-Json -Compress)
        }
    }

    # Authentication Flows
    $authFlows = @()
    if ($policy.Conditions.AuthenticationStrength) {
        if ($policy.Conditions.AuthenticationStrength.IncludeAuthenticationStrengths) {
            $authFlows += "IncludeAuthenticationStrengths: " + ($policy.Conditions.AuthenticationStrength.IncludeAuthenticationStrengths -join "; ")
        }
        if ($policy.Conditions.AuthenticationStrength.ExcludeAuthenticationStrengths) {
            $authFlows += "ExcludeAuthenticationStrengths: " + ($policy.Conditions.AuthenticationStrength.ExcludeAuthenticationStrengths -join "; ")
        }
    }

    $conditionsFull = @(
        "Platforms: $platforms",
        "ExcludePlatforms: $excludePlat",
        "Locations: $includeLoc",
        "ExcludeLocations: $excludeLoc",
        "ClientApps: $clientApps",
        "SignInRisk: $signInRisk",
        "UserRisk: $userRisk",
        ($deviceFilters -join "; "),
        ($authFlows -join "; ")
    ) -join " | "

    # Grant Controls
    $grantAction = ""
    if ($policy.GrantControls) {
        if ($policy.GrantControls.BuiltInControls -contains "block") {
            $grantAction = "Block Access"
        }
        elseif ($policy.GrantControls.BuiltInControls) {
            $grantAction = "Grant Access: " + ($policy.GrantControls.BuiltInControls -join "; ")
        }
        elseif ($policy.GrantControls.CustomAuthenticationFactors) {
            $grantAction = "Grant Access: Custom Factors - " + ($policy.GrantControls.CustomAuthenticationFactors -join "; ")
        }
    }

    # Session Controls
    $session = @()
    if ($policy.SessionControls) {
        if ($policy.SessionControls.ApplicationEnforcedRestrictions.IsEnabled) { $session += "AppEnforcedRestrictions" }
        if ($policy.SessionControls.PersistentBrowser.IsEnabled) { $session += "PersistentBrowser=$($policy.SessionControls.PersistentBrowser.Mode)" }
        if ($policy.SessionControls.SignInFrequency.IsEnabled) { $session += "SignInFrequency=$($policy.SessionControls.SignInFrequency.Value) $($policy.SessionControls.SignInFrequency.Type)" }
        if ($policy.SessionControls.CloudAppSecurity.IsEnabled) { $session += "CloudAppSecurity=$($policy.SessionControls.CloudAppSecurity.CloudAppSecurityType)" }
    }

    $results += [pscustomobject]@{
        PolicyName      = $policy.DisplayName
        State           = $policy.State
        IncludeUsers    = $includeUsers
        ExcludeUsers    = $excludeUsers
        IncludeGroups   = $includeGroups
        ExcludeGroups   = $excludeGroups
        IncludeRoles    = $includeRoles
        ExcludeRoles    = $excludeRoles
        IncludeApps     = $includeApps
        ExcludeApps     = $excludeApps
        Conditions      = $conditionsFull
        GrantControls   = $grantAction
        SessionControls = ($session -join "; ")
    }
}

# Export to CSV
$results | Export-Csv -Path ".\CA-Policies.csv" -NoTypeInformation -Encoding UTF8
