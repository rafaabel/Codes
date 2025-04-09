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

function Get-EntraConnectSyncStatus {
    # Retrieve tenant organization information
    $organization = Get-MgOrganization -OrganizationId $tenantId | Select-Object OnPremisesLastSyncDateTime
    # Extract the last sync date and time
    $lastSyncDateTime = $organization.OnPremisesLastSyncDateTime
    # Convert local server time to UTC
    $localTimeUTC = (Get-Date).ToUniversalTime()
    # Calculate the sync duration
    $syncDuration = $localTimeUTC - $lastSyncDateTime
    return @{
        SyncDuration = $syncDuration
        LastSync     = $lastSyncDateTime
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
$EmailFrom = "uber@uber.com"
$EmailToAddresses = @("rgonca10@ext.uber.com")
$Subject = "Entra Connect Sync Duration Alert"

# Check sync status
$status = Get-EntraConnectSyncStatus
if ($status.SyncDuration.TotalHours -gt 1) {
    # Build email content
    $Body = @"
 <head>
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400&display=swap" rel="stylesheet">
</head>
<body style="font-family: 'Montserrat', sans-serif; font-size: 18px;">
    <div>
        <img src="https://cdn-assets-us.frontify.com/s3/frontify-enterprise-files-us/eyJwYXRoIjoicG9zdG1hdGVzXC9hY2NvdW50c1wvODRcLzQwMDA1MTRcL3Byb2plY3RzXC8yN1wvYXNzZXRzXC9lZFwvNTUwOVwvNmNmOGVmM2YzMjFkMTA3YThmZGVjNjY1NjJlMmVmMzctMTYyMDM3Nzc0OC5haSJ9:postmates:9KZWqmYNXpeGs6pQy4UCsx5EL3qq29lhFS6e4ZVfQrs?width=2400" 
             alt="Descriptive Alt Text" 
             width="177" 
             style="display: block; margin: 0 auto;">
    </div>

    <div>
        <p>Hello,</p>
        <p>The Entra Connect sync process has exceeded 1 hour.</p>
        <table style="width: 100%; border-collapse: collapse;">
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Last Sync</th>
                <td style="padding: 8px;">$($status.LastSync)</td>
            </tr>
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Sync Duration (hours)</th>
                <td style="padding: 8px;">$($status.SyncDuration)</td>
            </tr>
        </table>
    </div>  
"@

    # Build JSON Payload for Postmaster
    $Payload = [ordered]@{
        id          = [guid]::NewGuid().ToString()
        fromEmail   = $EmailFrom
        recipients  = [ordered]@{
            to = [ordered]@{
                emailAddress = $EmailToAddresses | ForEach-Object { $_ }
            }
        }
        content     = [ordered]@{
            rawEmail = [ordered]@{
                subject  = $Subject
                richBody = $Body
            }
        }
        messageType = "internal"
    }

    # Convert the payload to JSON with custom depth
    $JsonPayload = $Payload | ConvertTo-Json -Depth 10 -Compress

    # Send the email using Postmaster API
    $Headers = @{ 
        Authorization  = "Bearer $AccessToken"
        "Content-Type" = "text/plain"
    }

    $Response = Invoke-RestMethod -Uri $PostmasterApiUrl -Method Post -Headers $Headers -Body $JsonPayload -ContentType "application/json"
    #Write-Host "Raw Response Content: $($Response.Content)" 

    # Output Response
    if ($Response.StatusCode -eq 202) {
        Write-Host "Email sent successfully."
    }
    else {
        Write-Host "Failed to send email."
        Write-Host $Response
    }
}
 
# Disconnect from Microsoft Graph
Disconnect-MgGraph
