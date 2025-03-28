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

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "AuditLog.Read.All", "User.Read.All"

# Fetch all guest users
$guestUsers = Get-MgUser -Filter "userType eq 'Guest'" -Property "Id,DisplayName,UserPrincipalName,UserType,CreationType,CreatedDateTime,SignInActivity" -All

# Filter users based on last interactive and non-interactive sign-ins within 90 days
$cutoffDate = (Get-Date).AddDays(-90)

$inactiveUsers = $guestUsers | Where-Object {
    $_.SignInActivity.LastSignInDateTime -lt $cutoffDate -and
    $_.SignInActivity.LastNonInteractiveSignInDateTime -lt $cutoffDate
}

# Prepare an array to store user data along with their group memberships
$results = @()

foreach ($user in $inactiveUsers) {
    # Fetch group memberships for the user, ensuring display names are retrieved
    $groups = Get-MgUserMemberOf -UserId $user.Id | % {($_.AdditionalProperties).displayName}

    # Add user data along with groups to the results
    $results += [PSCustomObject]@{
        UserId                       = $user.Id
        DisplayName                  = $user.DisplayName
        UserPrincipalName            = $user.UserPrincipalName
        UserType                     = $user.UserType
        CreationType                 = $user.CreationType
        CreationDate                 = $user.CreatedDateTime
        LastInteractiveSignInTime    = $user.SignInActivity.LastSignInDateTime
        LastNonInteractiveSignInTime = $user.SignInActivity.LastNonInteractiveSignInDateTime
        GroupMemberships             = $groups -join "; "
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "InactiveGuestUsersWithGroups.csv" -NoTypeInformation -Encoding UTF8
