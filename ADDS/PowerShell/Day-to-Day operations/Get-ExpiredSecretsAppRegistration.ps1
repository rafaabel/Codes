<#
.SYNOPSIS
    Exports App Registrations with secrets or certificates expiring within 30 days.

.DESCRIPTION
    Connects to Microsoft Graph and retrieves every application registration in the
    tenant, checking each one's password credentials (secrets) and key credentials
    (certificates) for an expiration date within the next 30 days. For each matching
    credential, the application owner is resolved and the finding is added to the
    in-memory log, which can then be exported to a CSV file for review.

.NOTES
    Author       : Microsoft
                   ref: https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/scripts/powershell-export-apps-with-expiring-secrets
                   ref: https://stackoverflow.com/questions/79031777/export-app-registrations-with-expiring-secrets-and-certificates-and-send-alert-i
    Date         : 02/16/2022
    Requirements : Connect to Entra ID as Global Administrator
#>


Connect-MgGraph -Scopes 'Application.Read.All'

$DaysUntilExpiration = 30
$Now = Get-Date
$Logs = @()

Write-Host "Retrieving all applications... This may take a while." -ForegroundColor Yellow
$Applications = Get-MgApplication -all

foreach ($App in $Applications) {
    $AppName = $App.DisplayName
    $AppID   = $App.Id
    $ApplID  = $App.AppId

    $AppCreds = Get-MgApplication -ApplicationId $AppID | Select-Object PasswordCredentials, KeyCredentials
    $Secrets  = $AppCreds.PasswordCredentials
    $Certs    = $AppCreds.KeyCredentials

    foreach ($Secret in $Secrets) {
        $StartDate  = $Secret.StartDateTime
        $EndDate    = $Secret.EndDateTime
        $SecretName = $Secret.DisplayName
        $RemainingDaysCount = ($EndDate - $Now).Days

        if ($RemainingDaysCount -lt 30 -and $RemainingDaysCount -ge 0) {
            $Owner    = Get-MgApplicationOwner -ApplicationId $App.Id
            $Username = $Owner.AdditionalProperties.userPrincipalName -join ';'
            $OwnerID  = $Owner.Id -join ';'

            if ($null -eq $Owner.AdditionalProperties.userPrincipalName) {
                $Username = $Owner.AdditionalProperties.displayName + ' **<This is an Application>**'
            }
            if ($null -eq $Owner.AdditionalProperties.displayName) {
                $Username = '<<No Owner>>'
            }

            $Logs += [PSCustomObject]@{
                'ApplicationName'        = $AppName
                'ApplicationID'          = $ApplID
                'Secret Name'            = $SecretName
                'Secret Start Date'      = $StartDate
                'Secret End Date'        = $EndDate
                'ExpiresInDays'          = $RemainingDaysCount
                'Certificate Name'       = $Null
                'Certificate Start Date' = $Null
                'Certificate End Date'   = $Null
                'Owner'                  = $Username
                'Owner_ObjectID'         = $OwnerID
            }
        }
    }

    foreach ($Cert in $Certs) {
        $StartDate = $Cert.StartDateTime
        $EndDate   = $Cert.EndDateTime
        $CertName  = $Cert.DisplayName
        $RemainingDaysCount = ($EndDate - $Now).Days

        if ($RemainingDaysCount -lt 30 -and $RemainingDaysCount -ge 0) {
            $Owner    = Get-MgApplicationOwner -ApplicationId $App.Id
            $Username = $Owner.AdditionalProperties.userPrincipalName -join ';'
            $OwnerID  = $Owner.Id -join ';'

            if ($null -eq $Owner.AdditionalProperties.userPrincipalName) {
                $Username = $Owner.AdditionalProperties.displayName + ' **<This is an Application>**'
            }
            if ($null -eq $Owner.AdditionalProperties.displayName) {
                $Username = '<<No Owner>>'
            }

            $Logs += [PSCustomObject]@{
                'ApplicationName'        = $AppName
                'ApplicationID'          = $ApplID
                'Secret Name'            = $Null
                'Certificate Name'       = $CertName
                'Certificate Start Date' = $StartDate
                'Certificate End Date'   = $EndDate
                'ExpiresInDays'          = $RemainingDaysCount
                'Owner'                  = $Username
                'Owner_ObjectID'         = $OwnerID
            }
        }
    }
}
