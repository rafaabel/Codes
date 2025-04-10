<#
.Synopsis
   Monitor Entra ID Directory Size Quota and send notifications
.DESCRIPTION
   Check Entra ID Directory Size Quota and notify users via email using Postman
.REQUIREMENTS
   App Registrations: https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app?tabs=certificate%2Cexpose-a-web-api
   Microsoft Graph PowerShell SDK: https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0
   SecretManagement and SecretStore modules: https://learn.microsoft.com/en-us/powershell/utility-modules/secretmanagement/get-started/using-secretstore?view=ps-modules
   Postman OAuth 2.0: https://learning.postman.com/docs/sending-requests/authorization/oauth-20/
.AUTHOR
   Rafael Abel - rgonca10@ext.uber.com
.DATE
   04/10/2025
#>

# Retrieve SecretStore vault password and open it
$securedPasswordPath = "C:\Task Scheduler scripts\passwd.xml"
$password = Import-CliXml -Path $securedPasswordPath
Unlock-SecretStore -Password $password

# Set tenantId, clientId and securedClientSecret by retrieving SendMailEntraSyncSecret value from SecretStore vault
$tenantId = "your-tenand-id"
$clientId = "your-client-id"
$securedClientSecret = Get-Secret -Name "SendMailObjectQuotaSecret"

# Create the ClientSecretCredential object
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, $securedClientSecret

# Authenticate with Microsoft Graph
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $ClientSecretCredential

# Function to fetch directory size quota and process data
 function Get-DirectorySizeQuotaStatus {
    $graphData = (Get-MgOrganization -OrganizationId $tenantId -Property *).AdditionalProperties["directorySizeQuota"]
    if ($null -ne $graphData) {
        $used = $graphData["used"]
        $total = $graphData["total"]
        $usedPercentage = [math]::Round(($used / $total) * 100, 2)
        return @{
            Used           = $used
            Total          = $total
            UsedPercentage = $usedPercentage
        }
    }
    else {
        Write-Output "Failed to retrieve or parse directory size data from Microsoft Graph API."
        return $null
    }
} 


# Postman email endpoint
$PostmanApiUrl = "https://postmanendpoint.com/email"

# OAuth2 token endpoint
$TokenEndpoint = "https://tokenendpoint.com/oauth2/token"

# Base64 encode client_id and client_secret
$oauth_app_client_id = "your-oauth_app-client-id"
$oauth_app_client_secret = "your-oauth_app-client-secret"
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${oauth_app_client_id}:${oauth_app_client_secret}"))

# Token request
$TokenRequestHeader = @{ Authorization = "Basic $encodedCredentials" }
$TokenRequestBody = @{
    grant_type = "client_credentials"
    audience   = "postmanendpoint.com"
}
$TokenResponse = Invoke-RestMethod -Uri $TokenEndpoint -Method Post -Headers $TokenRequestHeader -Body $TokenRequestBody -ContentType "application/x-www-form-urlencoded"
$AccessToken = $TokenResponse.access_token

# Email parameters
$EmailFrom = "uber@uber.com"
$EmailToAddresses = @("rgonca10@ext.uber.com")

# Fetch and evaluate directory size quota
$status = Get-DirectorySizeQuotaStatus
if ($null -ne $status) {
    $used = $status.Used
    $total = $status.Total
    $usedPercentage = $status.UsedPercentage

    # Determine email content based on usage percentage
    if ($usedPercentage -le 90) {
        $subject = "Entra ID Directory size quota is within threshold - All is okay!"
        $body = @"
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
         <p>Entra ID Directory size quota is within threshold. No action needed!</p>
        <table style="width: 100%; border-collapse: collapse; margin-top: 20px;">
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Used Objects</th>
                        <td style="padding: 8px;">$used</td>
            </tr>
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Maximum Size Objects</th>
                <td style="padding: 8px;">$total</td>
            </tr>
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Usage Percentage</th>
                <td style="padding: 8px;">$([math]::Round($usedPercentage, 2))%</td>
             </tr>
          </table>
    </div>
</body>
"@
    }
    elseif ($usedPercentage -gt 90 -and $usedPercentage -le 95) {
        $subject = "Entra ID Directory size quota will soon be exceeded!"
        $body = @"
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
         <p>Entra ID Directory size quota will soon be exceeded!</p>
        <table style="width: 100%; border-collapse: collapse; margin-top: 20px;">
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Used Objects</th>
                        <td style="padding: 8px;">$used</td>
            </tr>
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Maximum Size Objects</th>
                <td style="padding: 8px;">$total</td>
            </tr>
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Usage Percentage</th>
                <td style="padding: 8px;">$([math]::Round($usedPercentage, 2))%</td>
             </tr>
          </table>
    </div>
</body>
"@
    }
    elseif ($usedPercentage -gt 95 -and $usedPercentage -le 100) {
        $subject = "Entra ID Directory size quota nearing critical threshold - Action required!"
        $body = @"
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
         <p>Entra ID Directory size quota nearing critical threshold - Action required!</p>
        <table style="width: 100%; border-collapse: collapse; margin-top: 20px;">
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Used Objects</th>
                        <td style="padding: 8px;">$used</td>
            </tr>
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Maximum Size Objects</th>
                <td style="padding: 8px;">$total</td>
            </tr>
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Usage Percentage</th>
                <td style="padding: 8px;">$([math]::Round($usedPercentage, 2))%</td>
             </tr>
          </table>
    </div>
</body>
"@
    }
    elseif ($usedPercentage -gt 100) {
        $subject = "Entra ID Directory size quota exceeded - Critical action required!"
        $body = @"
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
         <p>Entra ID Directory size quota exceeded - Critical action required!</p>
        <table style="width: 100%; border-collapse: collapse; margin-top: 20px;">
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Used Objects</th>
                        <td style="padding: 8px;">$used</td>
            </tr>
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Maximum Size Objects</th>
                <td style="padding: 8px;">$total</td>
            </tr>
            <tr>
                <th style="text-align: left; vertical-align: middle; padding: 8px;">Usage Percentage</th>
                <td style="padding: 8px;">$([math]::Round($usedPercentage, 2))%</td>
             </tr>
          </table>
    </div>
</body>
"@
    }

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
                subject  = $subject
                richBody = $body
            }
        }
        messageType = "internal"
    }

    # Convert the payload to JSON with custom depth
    $JsonPayload = $Payload | ConvertTo-Json -Depth 10 -Compress

    # Send the email using Postmaster API
    $Headers = @{ 
        Authorization  = "Bearer $AccessToken"
        "Content-Type" = "application/json"
    }

    Invoke-RestMethod -Uri $PostmasterApiUrl -Method Post -Headers $Headers -Body $JsonPayload -ContentType "application/json"
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
