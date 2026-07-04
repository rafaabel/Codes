<#
.SYNOPSIS
    Retrieves issued certificate requests grouped by Certificate Template.

.DESCRIPTION
    Uses the PSPKI module to query a specified Certification Authority for all
    certificates issued within the last 2 years, then resolves each certificate's
    template OID to its friendly name. The results are exported to a CSV file for
    reporting on certificate template usage.

.NOTES
    Author       : Rafael Abel - rafael.abel@effem.com
    Date         : 03/11/2023
    Requirements : This script must be run from any DC
                   PSPKI module: https://www.pkisolutions.com/tools/pspki/
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
