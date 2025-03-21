<#
.Synopsis
   Script to remove all App Registrations secrets and certificates
.DESCRIPTION
   Script to remove all App Registrations secrets and certificates with expiration date older than x days
.REQUIREMENTS
   Install the Microsoft Graph PowerShell SDK: https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0
.AUTHOR
   Rafael Abel - rgonca10@ext.uber.com
.DATE
   03/19/2025
#>

# Connect to Microsoft Graph API

Connect-MgGraph -Scopes "Application.ReadWrite.All"

# Define the path to the input and output CSV files

$inputCsvFilePath = "ExpiredApplications.csv"

$outputCsvFilePath = "DeletedExpiredCredentials.csv"

# Import the expired applications from the input CSV file

$expiredApps = Import-Csv -Path $inputCsvFilePath

# Create an array to store details of successfully deleted credentials

$deletedCredentials = @()

# Loop through each application and attempt to delete expired secrets and certificates

foreach ($app in $expiredApps) {

    try {

        # Retrieve the application details by its AppId

        $application = Get-MgApplication -ApplicationId $app.ApplicationID

        # Delete expired secrets (PasswordCredentials)

        foreach ($secret in $application.PasswordCredentials | Where-Object { $_.KeyId -eq $app.SecretID }) {

            Remove-MgApplicationPassword -ApplicationId $application.Id -KeyId $secret.KeyId

            Write-Host "Deleted secret: $($app.SecretName) from application: $($application.DisplayName) (AppId: $($application.AppId))" -ForegroundColor Green

            

            # Add to the deletedCredentials array

            $deletedCredentials += [PSCustomObject]@{

                ApplicationName = $application.DisplayName

                ApplicationID   = $application.AppId

                CredentialType  = "Secret"

                CredentialID    = $secret.KeyId

                StartDate       = $secret.StartDateTime

                EndDate         = $secret.EndDateTime

            }

        }



        # Delete expired certificates (KeyCredentials)

        foreach ($cert in $application.KeyCredentials | Where-Object { $_.KeyId -eq $app.CertificateID }) {

            Remove-MgApplicationKey -ApplicationId $application.Id -KeyId $cert.KeyId

            Write-Host "Deleted certificate: $($app.CertificateName) from application: $($application.DisplayName) (AppId: $($application.AppId))" -ForegroundColor Green

            

            # Add to the deletedCredentials array

            $deletedCredentials += [PSCustomObject]@{

                ApplicationName = $application.DisplayName

                ApplicationID   = $application.AppId

                CredentialType  = "Certificate"

                CredentialID    = $cert.KeyId

                StartDate       = $cert.StartDateTime

                EndDate         = $cert.EndDateTime

            }

        }

    } catch {

        # Handle any errors

        Write-Host "Failed to delete credentials for application: $($app.ApplicationName) (AppId: $($app.ApplicationID)). Error: $_" -ForegroundColor Red

    }

}

# Export the details of deleted credentials to the output CSV file

$deletedCredentials | Export-Csv -Path $outputCsvFilePath -NoTypeInformation

Write-Host "Deleted credentials have been exported to $outputCsvFilePath"
