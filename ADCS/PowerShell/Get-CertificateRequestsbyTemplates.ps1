<#
.Synopsis
   Retrieve certificates requests
.DESCRIPTION
   Retrieve certificates requests by Certificate Templates
.REQUIREMENTS
   This script must be run from any DC
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
   https://www.pkisolutions.com/tools/pspki/
.DATE
   03/11/2023
#>

#Import PSKI Module
Import-Module PSPKI

#Variables
$CA = "Mars Inc ISXS187"

#Store the information from every certificate issued by certificate template in the last 2 years into the array
[System.Collections.ArrayList]$certbytemplate = @(Get-CertificationAuthority -Name $CA `
  | Get-IssuedRequest -Filter "NotBefore -ge $((Get-Date).AddYears(-2))"`
  | Select-Object -ExpandProperty CertificateTemplate)

#Get every certificate by certificate template and find its respective friendly name
$output = ForEach ($i in $certbytemplate) {

  Get-ObjectIdentifier $i 

}

#Output the array content to the CSV File
$output | Export-CsV 'D:\Scripts\retrieve_certificates_requests_by_certificate_templates.csv'
