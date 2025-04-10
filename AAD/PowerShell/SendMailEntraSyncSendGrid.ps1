<#
.Synopsis
   Monitor Entra Connect Sync status and send notifications
.DESCRIPTION
   Check if Entra Connect Sync duration exceeds 1 hour and notify users via email using SendGrid API
.REQUIREMENTS
   App Registrations: https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app?tabs=certificate%2Cexpose-a-web-api
   Microsoft Graph PowerShell SDK: https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0
   SecretManagement and SecretStore modules: https://learn.microsoft.com/en-us/powershell/utility-modules/secretmanagement/get-started/using-secretstore?view=ps-modules
   SendGrid API Key: https://sendgrid.com/
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
$tenantId = "your-tenand-id"
$clientId = "your-client-id"
$securedClientSecret = Get-Secret -Name "SendMailEntraSyncSecret"

# Create the ClientSecretCredential object
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, $securedClientSecret

# Authenticate with Microsoft Graph
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $ClientSecretCredential

# Function to check Entra Connect Sync status
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

# Set SendGrid API details
$SendGridApiUrl = "https://api.sendgrid.com/v3/mail/send"
$securedSendGridApiKey = Get-Secret -Name "SendGridApiKey"

# Set email parameters
$EmailFrom = "corpsys-alerts@uber.com"
$EmailToAddresses = @("rgonca10@ext.uber.com")
$Subject = "Entra Connect Sync Duration Alert"

# Check sync status
$status = Get-EntraConnectSyncStatus
if ($status.SyncDuration.TotalHours -gt 1) {
    # Format SyncDuration to exclude milliseconds
    $formattedSyncDuration = $status.SyncDuration.ToString("hh\:mm\:ss") 
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
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Last Sync (UTC)</th>
                <td style="padding: 8px;">$($status.LastSync)</td>
            </tr>
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Sync Duration (hh\mm\ss)</th>
                <td style="padding: 8px;">$($formattedSyncDuration)</td> 
            </tr>
        </table>
    </div> 
"@

    # Build JSON payload for SendGrid
    $Payload = @{
        personalizations = @(@{ to = @($EmailToAddresses | ForEach-Object { @{ email = $_ } }) })
        from = @{ email = $EmailFrom }
        subject = $Subject
        content = @(@{ type = "text/html"; value = $Body })
    }

    $JsonPayload = $Payload | ConvertTo-Json -Depth 10 

    # Send email using SendGrid
    $Headers = @{ Authorization = "Bearer $securedSendGridApiKey" }
    $Response = Invoke-RestMethod -Uri $SendGridApiUrl -Method Post -Headers $Headers -Body $JsonPayload -ContentType "application/json"

    # Output response
    if ($Response.StatusCode -eq 202) {
        Write-Host "Email sent successfully."
    } else {
        Write-Host "Failed to send email."
        Write-Host $Response
    }
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
