[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-LicenseName.ps1"
Describe "Get-LicenseNames"{
    It "Script Should Exists" {
        (Test-Path "$here\..\Get-LicenseName.ps1") | Should Be $True
    }
    It "Should not throw" {
        {Get-LicenseName} | Should Not Throw
    }
    It "Should return license information if passed a license SKU" {
        $licenseParts = @()
        $licenseParts += "AAD_PREMIUM"
        $licenseParts += "O365_Business"
        $licenseParts += "O365_Business_FAKE"
        Get-LicenseName -licenseparts $licenseParts -Warningaction silentlycontinue | Should Not Be Null
    }
    It "Should return empty string if no license is passed in" {
        Get-LicenseName -licenseparts $null | Should Be ""
    }
}