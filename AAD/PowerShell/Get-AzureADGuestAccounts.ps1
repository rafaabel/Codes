<#
.Synopsis
   Script to get all Azure AD guest accounts
.DESCRIPTION
   Script to get all Azure AD guest accounts with last sign-in older than x days
.REQUIREMENTS
   Install the Microsoft Graph PowerShell SDK: https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0
.AUTHOR
   Rafael Abel - rgonca10@ext.uber.com
.DATE
   03/19/2025
#>

# Connect to Microsoft Graph API

Connect-MgGraph -Scopes "AuditLog.Read.All", "User.Read.All"

# Fetch all guest users

$guestUsers = Get-MgUser -Filter "userType eq 'Guest'" -Property "DisplayName,UserPrincipalName,UserType,CreationType,SignInActivity" -All

# Filter users based on last interactive and non-interactive sign-ins within 90 days

$cutoffDate = (Get-Date).AddDays(-90)

$inactiveUsers = $guestUsers | Where-Object {

    $_.SignInActivity.LastSignInDateTime -lt $cutoffDate -and

    $_.SignInActivity.LastNonInteractiveSignInDateTime -lt $cutoffDate

}

# Export all guest users

$inactiveUsers | Select-Object `

    DisplayName, `

    UserPrincipalName, `

    UserType, `

    CreationType, `

    @{Name="LastInteractiveSignInTime"; Expression={$_.SignInActivity.LastSignInDateTime}}, `

    @{Name="LastNonInteractiveSignInTime"; Expression={$_.SignInActivity.LastNonInteractiveSignInDateTime}} `

| Export-Csv -Path "InactiveGuestUsers.csv" -NoTypeInformation -Encoding UTF8
