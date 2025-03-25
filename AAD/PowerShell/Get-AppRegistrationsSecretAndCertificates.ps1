# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Application.Read.All", "User.Read.All"

# Define the expiration threshold (90 days ago for expired credentials)
$expirationThreshold = (Get-Date).AddDays(-90)

# Get all application registrations
$applications = Get-MgApplication -All

# Create an array to store applications with expired/expiring credentials
$expiredCredentialsApps = @()

# Loop through each application and check credentials
foreach ($app in $applications) {
    # Retrieve the owners for each application
    $owners = Get-MgApplicationOwner -ApplicationId $app.Id

    # Extract Owner Information
    $username = $owners.AdditionalProperties.userPrincipalName -join ';'
    $ownerID = $owners.Id -join ';'

    if ($null -eq $owners.AdditionalProperties.userPrincipalName) {
        $username = @(
            $owners.AdditionalProperties.displayName
            '**<This is an Application>**'
        ) -join ' '
    }

    if ($null -eq $owners.AdditionalProperties.displayName) {
        $username = '<<No Owner>>'
    }
    
    # Check PasswordCredentials (secrets)
    foreach ($secret in $app.PasswordCredentials | Where-Object { $_.EndDateTime -lt $expirationThreshold }) {
        $expiredCredentialsApps += [PSCustomObject]@{
            ApplicationName      = $app.DisplayName
            ApplicationID        = $app.AppId
            SecretID             = $secret.KeyId
            SecretStartDate      = $secret.StartDateTime
            SecretEndDate        = $secret.EndDateTime
            CertificateName      = "N/A"
            CertificateStartDate = "N/A"
            CertificateEndDate   = "N/A"
            Thumbprint           = "N/A"
            CertificateID        = "N/A"
            Owner                = $username
            Owner_ObjectID       = $ownerID
        }
    }
    
    # Check KeyCredentials (certificates)
    foreach ($cert in $app.KeyCredentials | Where-Object { $_.EndDateTime -lt $expirationThreshold }) {
        $expiredCredentialsApps += [PSCustomObject]@{
            ApplicationName      = $app.DisplayName
            ApplicationID        = $app.AppId
            SecretID             = "N/A"
            SecretStartDate      = "N/A"
            SecretEndDate        = "N/A"
            CertificateName      = $cert.DisplayName
            CertificateStartDate = $cert.StartDateTime
            CertificateEndDate   = $cert.EndDateTime
            Thumbprint           = $cert.Thumbprint
            CertificateID        = $cert.KeyId
            Owner                = $username
            Owner_ObjectID       = $ownerID
        }
    }
}

# Export applications with expired/expiring credentials to a CSV file
$csvFilePath = "ExpiredApplications.csv"
$expiredCredentialsApps | Export-Csv -Path $csvFilePath -NoTypeInformation
