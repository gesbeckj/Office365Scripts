[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-LicenseName.ps1"
Describe "Get-LicenseNames"{
    It "Script Should Exists" {
        (Test-Path "$here\..\Get-LicenseName.ps1") | Should Be $True
    }
    It "Should not thrw" {
        {Get-LicenseName} | Should Not Throw
    }
}