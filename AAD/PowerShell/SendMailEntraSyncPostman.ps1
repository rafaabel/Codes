<#
.Synopsis
   Monitor Entra Connect Sync status and send notifications
.DESCRIPTION
   Check if Entra Connect Sync duration exceeds 1 hour and notify users via email using Postman
.REQUIREMENTS
   App Registrations: https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app?tabs=certificate%2Cexpose-a-web-api
   Microsoft Graph PowerShell SDK: https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0
   SecretManagement and SecretStore modules: https://learn.microsoft.com/en-us/powershell/utility-modules/secretmanagement/get-started/using-secretstore?view=ps-modules
   Postman OAuth 2.0: https://learning.postman.com/docs/sending-requests/authorization/oauth-20/
.AUTHOR
   Rafael Abel - rgonca10@ext.uber.com
.DATE
   03/21/2025
#>

# Retrieve SecretStore vault password and open it
$securedPasswordPath = "C:\Task Scheduler scripts\passwd.xml"
$password = Import-CliXml -Path $securedPasswordPath
Unlock-SecretStore -Password $password

# Set tenantId, clientId and securedClientSecret by retrieving SendMailExpiredApplicationsSecret value from SecretStore vault
$tenantId = "your-tenand-id
$clientId = "your-client-id"
$securedClientSecret = Get-Secret -Name "SendMailEntraSyncSecret"

# Create the ClientSecretCredential object
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, $securedClientSecret

# Authenticate with Microsoft Graph
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $ClientSecretCredential

# Function to check Entra Connect Sync status
function Get-EntraConnectSyncStatus {
    $syncStatus = Get-MgDirectorySynchronization
    $lastSyncDateTime = $syncStatus.Context.LastSyncDateTime
    $syncDuration = (Get-Date) - $lastSyncDateTime
    return @{
        SyncDuration = $syncDuration
        LastSync = $lastSyncDateTime
    }
}

# Postman email endpoint
$PostmanApiUrl = "https://postmanendpoint.com/email"

# OAuth2 token endpoint
$TokenEndpoint = "https://tokenendpoint.com/oauth2/token"

# Base64 encode client_id and client_secret
$oauth_app_client_id  = "your-oauth_app-client-id"
$oauth_app_client_secret = "your-oauth_app-client-secret"
$credentials = "${oauth_app_client_id}:${oauth_app_client_secret}"
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($credentials))

# Token request Header
$TokenRequestHeader = @{
    Authorization = "Basic $encodedCredentials"
}

# Token request body
$TokenRequestBody = @{
    grant_type = "client_credentials"
    audience = "postmanendpoint.com"
}

$TokenResponse = Invoke-RestMethod -Uri $TokenEndpoint -Method Post -Headers $TokenRequestHeader -Body $TokenRequestBody -ContentType "application/x-www-form-urlencoded"
$AccessToken = $TokenResponse.access_token

# Set email parameters
$EmailFrom = "corpsys-alerts@uber.com"
$EmailToAddresses = @("rgonca10@ext.uber.com")
$Subject = "Entra Connect Sync Duration Alert"

# Check sync status
$status = Get-EntraConnectSyncStatus
if ($status.SyncDuration.TotalHours -gt 1) {
    # Build email content
    $Body = @"
<div>
    <p>Hello,</p>
    <p>The Entra Connect sync process has exceeded 1 hour.</p>
    <table>
        <tr>
            <th>Last Sync</th>
            <td>$($status.LastSync)</td>
        </tr>
        <tr>
            <th>Sync Duration (hours)</th>
            <td>$($status.SyncDuration.TotalHours)</td>
        </tr>
    </table>
</div>
"@

    # Build JSON payload for Postman
    $Payload = @{
        personalizations = @(@{ to = @($EmailToAddresses | ForEach-Object { @{ email = $_ } }) })
        from = @{ email = $EmailFrom }
        subject = $Subject
        content = @(@{ type = "text/html"; value = $Body })
    }

    $JsonPayload = $Payload | ConvertTo-Json -Depth 10

    # Send the email using Postman API
    $Headers = @{ Authorization = "Bearer $AccessToken" }
    $Response = Invoke-RestMethod -Uri $PostmanApiUrl -Method Post -Headers $Headers -Body $JsonPayload -ContentType "application/json"

    # Output Response
    if ($Response.StatusCode -eq 202) {
        Write-Host "Email sent successfully."
    } else {
        Write-Host "Failed to send email."
        Write-Host $Response
    }
 }
 
# Disconnect from Microsoft Graph
Disconnect-MgGraph
