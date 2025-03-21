 <#
.Synopsis
   Retrieve App Registrations secrets and certificates
.DESCRIPTION
   Check App Registrations secrets and certificates that are going to expire soon and notify users via email using SMTP
.REQUIREMENTS
   App Registrations: https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app?tabs=certificate%2Cexpose-a-web-api
   Microsoft Graph PowerShell SDK: https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0
   SecretManagement and SecretStore modules: https://learn.microsoft.com/en-us/powershell/utility-modules/secretmanagement/get-started/using-secretstore?view=ps-modules
.AUTHOR
   Rafael Abel - rgonca10@ext.uber.com
.DATE
   03/18/2025
#>

# Retrieve SecretStore vault password, open it and retrieve the client secret from SendMailExpiredApplications app
$securePasswordPath = "C:\Task Scheduler scripts\passwd.xml"
$password = Import-CliXml -Path $securePasswordPath
Unlock-SecretStore -Password $password
 
# Set tenantId, clientId and securedClientSecret
$tenantId = "5bd1450c-8b7b-4877-aab8-688d37a70b6e"
$clientId = "8a076ac8-6174-4b0e-a3b2-15a4082a0dd8"
$securedClientSecret = Get-Secret -Name "SendMailExpiredApplicationsSecret"
 
# Create the ClientSecretCredential object
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, $securedClientSecret
 
# Authenticate with Microsoft Graph
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $ClientSecretCredential 

# Define the date range for expiry
$Today = Get-Date
$ExpiryThreshold = $Today.AddDays(60)

# Retrieve all applications
$Applications = Get-MgApplication -All

# Initialize an array to store expiring secrets and certificates
$ExpireSoon = @()

# Loop through each application to check secrets and certificates
foreach ($App in $Applications) {
    # Check PasswordCredentials (Secrets)
    foreach ($Secret in $App.PasswordCredentials) {
        $ExpiresInDays = ($Secret.EndDateTime - $Today).Days
        if ($Secret.EndDateTime -le $ExpiryThreshold -and $ExpiresInDays -ge 0) {
            $ExpireSoon += [PSCustomObject]@{
                AppDisplayName = $App.DisplayName
                EndDate        = $Secret.EndDateTime
                ExpiresInDays  = $ExpiresInDays
                AppID_ClientID = $App.AppId
            }
        }
    }

    # Check KeyCredentials (Certificates)
    foreach ($Cert in $App.KeyCredentials) {
        $ExpiresInDays = ($Cert.EndDateTime - $Today).Days
        if ($Cert.EndDateTime -le $ExpiryThreshold -and $ExpiresInDays -ge 0) {
            $ExpireSoon += [PSCustomObject]@{
                AppDisplayName = $App.DisplayName
                EndDate        = $Cert.EndDateTime
                ExpiresInDays  = $ExpiresInDays
                AppID_ClientID = $App.AppId
            }
        }
    }
}

# HTML conversion
$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; align="right"}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: white;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

$HTML = $ExpireSoon | ConvertTo-Html -Property AppDisplayName, EndDate, ExpiresInDays, AppID_ClientID -Head $Header | Out-String

$SMTPServer = "stmp.sendgrid.net"
$EmailFrom = "corpsys-alerts@uber.com"
$EmailToAddresses = @("rgonca10@ext.uber.com")
$EmailTo = $EmailToAddresses
$Subject = "[ACTION] - Expiration Client Secrets and Certificates in Azure"

$Body = @"
<div class="box flex">
    <table align="Center" style="height: 14px; margin-left: auto; margin-right: auto;" width="212">
        <tbody>
            <tr>
                <td style="width: 99.375px;"><img src="https://cdn-assets-us.frontify.com/s3/frontify-enterprise-files-us/eyJwYXRoIjoicG9zdG1hdGVzXC9hY2NvdW50c1wvODRcLzQwMDA1MTRcL3Byb2plY3RzXC8yN1wvYXNzZXRzXC9lZFwvNTUwOVwvNmNmOGVmM2YzMjFkMTA3YThmZGVjNjY1NjJlMmVmMzctMTYyMDM3Nzc0OC5haSJ9:postmates:9KZWqmYNXpeGs6pQy4UCsx5EL3qq29lhFS6e4ZVfQrs?width=2400" alt="" width="177" class="fr-fic fr-dib"></td>
            </tr>
        </tbody>
    </table>
    <table align="Center" style="height: 58px; width: 686.84px; margin-left: auto; margin-right: auto;">
                <tbody>
					<tr>
						<td style="width: 680.84px;">
							<p>
								&nbsp;</p>
							<p>
								<span class="font-montserrat" style="font-size: 18px;">Hello,</span></p>
							<p>
								<span style="font-size: 18px;"><span class="font-montserrat">In this table, you have all the applications and service principals that are using client secrets or certificates that are near to expiration.</span></span></p>
							<p>
								<span style="font-size: 18px;"><span class="font-montserrat"><strong>What is expected of you?</strong></span></span></p>
							<p>
								<span style="font-size: 18px;"><span class="font-montserrat">If you are the owner of this object and need to create a new client secret or certificate, please raise a new automated request&nbsp;<a href="https://uberhub.uberinternal.com/now/nav/ui/classic/params/target/uberhub">here</a>. Search for your app using your Application Name and choose the Credential Type, submit form and then your Manager is going to receive an e-mail with new generated credential.</span></span></p>
							<p>
								<span style="font-size: 18px;"><span class="font-montserrat"><strong>What do you need to know?</strong></span></span></p>
							<p>
								<span style="font-size: 18px;"><span class="font-montserrat">Client secrets and certificates are used by applications, web applications and service principals for authenticating in the cloud and consuming information and services like APIs, Data lakes, &nbsp;etc.</span></span></p>
							<p>
								<span style="font-size: 18px;"><span class="font-montserrat">If your application is using one of those credentials, it will <strong>STOP </strong>once this credential expires.</span></span></p>
							<p>
								<span class="font-montserrat" style="font-size: 18px;">If you are no longer using this credential, it will expire and be deleted later on as part of our application lifecycle process.</span></p>
							<p>
								<span class="font-montserrat" style="font-size: 18px;">Please forward this message to whomever it may concern.</span></p>
							<p>
								&nbsp;</p>
						</td>
					</tr>
				</tbody>
    </table>
     <p><br></p>
    <table align="Center" style="height: 100%;" width="686.84px;">
        <tbody>
            <tr>$HTML</tr>
        </tbody>
    </table>
</div>
"@

Send-MailMessage -smtpServer $SMTPServer -Credential $cred -Usessl -Port 587 -from $EmailFrom -to $EmailTo -subject $Subject -Body $Body -BodyAsHtml

# Disconnect from Microsoft Graph
Disconnect-MgGraph
