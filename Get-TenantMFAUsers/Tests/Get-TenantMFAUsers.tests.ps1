[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-TenantMFAUsers.ps1"
. "$here\..\..\Common\Connect-TenantExchangeOnline.ps1"
. "$here\..\..\Common\Get-LicenseName.ps1"
. "$here\..\..\Common\Connect-Office365.ps1"
Describe "Get-TenantMFAUsers" {
    Function Get-MsolPartnerContract {}
    Function Get-MsolUser {}
    It "Script Should Exists" {
        (Test-Path "$here\..\Get-TenantMFAUsers.ps1") | Should Be $True
    }
    It "Should not throw"{
        {Get-TenantMFAUsers} | Should Not Throw
    }
}