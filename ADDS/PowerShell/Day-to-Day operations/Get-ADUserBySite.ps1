<#
.Synopsis
   Get domain users by site
.DESCRIPTION
   Disable all inactive accounts from spreadsheet
.REQUIREMENTS
   Get domain users by site
.AUTHOR
   Marcos Junior - marcos.junior@effem.com
.DATE
   08/05/2022
#>

#Inform location where file will be generated
$outputFile = "C:\Temp\file.xlsx"
$excel = New-Object -ComObject excel.application
$excel.visible = $true
$workbook = $excel.workbooks.add()
$ws = $workbook.Worksheets.Item(1)
$ws.Name = "Users information"
$ws.Cells.Item(1, 1) = "First Name"
$ws.Cells.Item(1, 2) = "Last Name"
$ws.Cells.Item(1, 3) = "Display Name"
$ws.Cells.Item(1, 4) = "Email"
$ws.Cells.Item(1, 5) = "Employee ID"
$ws.Cells.Item(1, 6) = "Employee Type"
$ws.Cells.Item(1, 7) = "Site Location"
$ws.Cells.Item(1, 8) = "Region"
$ws.Cells.Item(1, 9) = "Segment"
$ws.Cells.Item(1, 10) = "Line Manager"
$ws.Cells.Item(1, 11) = "Line Manager 2"
$currRow = 2
#Generating user list with site location
$location = "SITECODE"
$users = Get-QADUser -LdapFilter "(&(extensionattribute15= $location)(userAccountControl=512))" -IncludedProperties extensionAttribute14, extensionAttribute15, employeeID, co
#Extracting data from Microsoft Excel
$counter = 1
foreach ($user in $users) {
   Write-Host "Extracting the information $counter of $($users.Count) - $($user.Name)" -ForegroundColor Green
   #Get-QADUser -LdapFilter "(&(extensionAttribute15= $location)(userAccountControl=512))" 
   $_user = $user
   $ws.Cells.Item($currRow, 1) = $_user.FirstName
   $ws.Cells.Item($currRow, 2) = $_user.LastName
   $ws.Cells.Item($currRow, 3) = $_user.DisplayName
   $ws.Cells.Item($currRow, 4) = $_user.mail
   $ws.Cells.Item($currRow, 5) = $_user.EmployeeID
   $ws.Cells.Item($currRow, 6) = $_user.extensionAttribute14
   $ws.Cells.Item($currRow, 7) = $_user.extensionAttribute15
   $ws.Cells.Item($currRow, 8) = $_user.co
   $ws.Cells.Item($currRow, 9) = $_user.Department
   $lm = $_user.Manager | Get-QADUser
   $lm2 = $lm.Manager | Get-QADUser
   $ws.Cells.Item($currRow, 10) = $lm.DisplayName
   $ws.Cells.Item($currRow, 11) = $lm2.DisplayName
   $currRow++
   $ws.UsedRange.EntireColumn.AutoFit() | Out-Null
   $counter++
}
$ws.SaveAs($outputFile)
$workbook.Close()
$excel.Quit()