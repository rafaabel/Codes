
<#
.Synopsis
   Retrieve all users from MPG from on-prem and Azure AD
.DESCRIPTION
   Retrieve all users from MPG from on-prem and Azure AD 
.REQUIREMENTS
   This script can be run from any domain joined computer
   AzureAD module
   ARS module
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
   Marcos Junior - marcos.junior@effem.com
.DATE
   08/03/2022
#>

#Get members from on-prem AD Most Powerfull Groups (MPG)
Import-Module ActiveRolesManagementShell
Import-Module AzureAd

Connect-QADService -Proxy vmww4617
Connect-AzureAD

$DomainMPGFilter = '(&(objectClass=group)(AdminCount=1) (( | (cn=Administrators)(cn=Enterprise Admins)(cn=Domain Admins)(cn=Backup Operators)(cn=Server Operators)(cn=Replicator)(cn=Account Operators)(cn=Domain Controllers)(cn=Read-only Domain Controllers)(cn=Schema Admins)(cn=Print Operators)(cn=Key Admins)(cn=Enterprise Key Admins))))'
$SearchRoot = 'MARS-AD.NET/', 'RCAD.NET/', 'MFG.MARS/', 'AM.MFG.MARS/', 'EU.MFG.MARS/', 'AP.MFG.MARS/'
#$SearchRoot = @('AP.MFG.MARS/')

$excel = New-Object -ComObject excel.application
$excel.visible = $true
$excel = $excel.workbooks.add()

For ($i = 0; $i -lt $SearchRoot.Count; $i++) {
   $ws = $excel.Worksheets.Item(1) #select tab
   $ws.Name = $SearchRoot[$i].Replace('/', '')
   $ws.Cells.Item(1, 1) = "DisplayName"
   $ws.Cells.Item(1, 2) = "SamAccountName"
   $ws.Cells.Item(1, 3) = "mail"
   $ws.Cells.Item(1, 4) = "DistinguishedName"
   $ws.Cells.Item(1, 5) = "co"
   $ws.Cells.Item(1, 6) = "Group Name"
   $currRow = 2
   $groupCounter = 1
   try {
      $DomainMPG = Get-QADgroup -LDAPFilter $DomainMPGFilter -SearchRoot $SearchRoot[$i]
   }
   catch {
      Write-Host "An error occurred:"
      Write-Host $_
      $excel.Worksheets.Add()
      continue
   }
   foreach ($domaingroup in $DomainMPG) {
      $members = Get-QADGroupMember -Identity $domaingroup.DN -IncludeAllProperties -Indirect | select DisplayName, SamAccountName, mail, DistinguishedName, co
      Write-Host "Extracting members of $($domaingroup.Name) - Total members: $($members.Count)" -ForegroundColor Green
      foreach ($member in $members) {
         $ws.Cells.Item($currRow, 1) = $member.DisplayName
         $ws.Cells.Item($currRow, 2) = $member.samAccountName
         $ws.Cells.Item($currRow, 3) = $member.mail
         $ws.Cells.Item($currRow, 4) = $member.DistinguishedName
         $ws.Cells.Item($currRow, 5) = $member.co
         $ws.Cells.Item($currRow, 6) = $domaingroup.Name
         $currRow++
      }
      $ws.UsedRange.EntireColumn.AutoFit() | Out-Null
      $groupCounter++
   }
   $excel.Worksheets.Add() #create tab
}

#Get members from Azure AD Privileged Roles
$AzureADPrivilegedRoles = 'Global Administrator', 'Identity Governance Administrator', 'User Administrator', 'Application Administrator', 'Cloud Application Administrator', 'Privileged Role Administrator'

$ws = $excel.Worksheets.Item(1) #select tab
$ws.Name = "Azure AD"
$ws.Cells.Item(1, 1) = "DisplayName"
$ws.Cells.Item(1, 2) = "UserPrincipalName"
$ws.Cells.Item(1, 3) = "Role"
$currRow = 2

foreach ($azureadprivilegerole in $AzureADPrivilegedRoles) {
   $Role = Get-AzureADDirectoryRole  | Where { $_.DisplayName -eq $azureadprivilegerole }
   $RoleMember = Get-AzureADDirectoryRoleMember -ObjectId $Role.ObjectId 
   
   foreach ($member in $RoleMember) {
      $ws.Cells.Item($currRow, 1) = $member.DisplayName
      $ws.Cells.Item($currRow, 2) = $member.UserPrincipalName
      $ws.Cells.Item($currRow, 3) = $azureadprivilegerole
      
      $currRow++
   }
   $ws.UsedRange.EntireColumn.AutoFit() | Out-Null
}

$ws.SaveAs("C:\Temp\MPGGroups.xlsx")