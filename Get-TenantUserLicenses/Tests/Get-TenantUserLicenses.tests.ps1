[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-TenantUserLicenses.ps1"
. "$here\..\..\Common\Connect-TenantExchangeOnline.ps1"
. "$here\..\..\Common\Get-LicenseName.ps1"
. "$here\..\..\Common\Connect-Office365.ps1"
Describe "Get-TenantUserLicenses" {
    It "Script Should Exists" {
        (Test-Path "$here\..\Get-TenantUserLicenses.ps1") | Should Be $True
    }
    It 'If it cannot connect to Office 365 it should throw'{
        $password = 'bogus' | ConvertTo-SecureString -AsPlainText -Force
        $cred = New-Object pscredential('bogus', $password)
        function Get-Credential {
            return $cred 
        }
        Mock -Command Connect-TenantExchangeOnline {Return $null}
        {Get-TenantUserLicenses -ErrorAction SilentlyContinue } | Should Throw
    }
}