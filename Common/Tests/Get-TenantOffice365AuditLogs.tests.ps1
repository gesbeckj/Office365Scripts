[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-TenantOffice365AuditLogs.ps1"
. "$here\..\Common\Connect-TenantExchangeOnline.ps1"
. "$here\..\Common\Get-LicenseName.ps1"
. "$here\..\Common\Connect-Office365.ps1"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Describe "Get-TenantUserLicenses" {
    function Remove-PSSession {
    }
    function Import-PSSession {
        return 'Test'
    }
    It "Script Should Exists" {
        (Test-Path "$here\..\Get-TenantOffice365AuditLogs.ps1") | Should Be $True
    }
}