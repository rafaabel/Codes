<#
.Synopsis
   Monitor Entra Connect Sync status and send notifications
.DESCRIPTION
   Check if Entra Connect Sync duration exceeds 1 hour and notify users via email using SendGrid API
.REQUIREMENTS
   App Registrations: https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app?tabs=certificate%2Cexpose-a-web-api
   Microsoft Graph PowerShell SDK: https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0
   SecretManagement and SecretStore modules: https://learn.microsoft.com/en-us/powershell/utility-modules/secretmanagement/get-started/using-secretstore?view=ps-modules
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
$tenantId = "49fe69f8-5945-4b10-8ee0-50bae8708623"
$clientId = "5bd1450c-8b7b-4877-aab8-688d37a70b6e"
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

# Email parameters
$cred = Get-AutomationPSCredential -Name 'MAILBOX PLACED HERE ex.:rgonca10@ext.uber.com'
$SMTPServer = "smtp.office365.com"
$EmailFrom = "corpsys-alerts@uber.com"
$EmailToAddresses = @("rgonca10@ext.uber.com")
$EmailTo = $EmailToAddresses
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

}

Send-MailMessage -smtpServer $SMTPServer -Credential $cred -Usessl -Port 587 -from $EmailFrom -to $EmailTo -subject $Subject -Body $Body -BodyAsHtml

# Disconnect from Microsoft Graph
Disconnect-MgGraph
