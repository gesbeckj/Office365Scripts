[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-TenantUserLicenses.ps1"
Describe "Get-TenantUserLicenses" {
    It "Script Should Exists" {
        (Test-Path "$here\..\Get-TenantUserLicenses.ps1") | Should Be $True
    }
    It ""
}