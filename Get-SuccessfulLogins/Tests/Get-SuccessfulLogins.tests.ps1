[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-SuccessfulLogins.ps1"

Describe "Testing Get-SuccessfulLogins"{
    It "Script Should Exists"{
        (Test-Path "$here\..\Get-SuccessfulLogins.ps1") | Should Be $True
    }
    It "Should not throw"{
        {Get-SuccessfulLogins} | Should Not Throw
    }
    It "If no logins exists should return null"{
        Get-SuccessfulLogins | Should Be $null
    }
    It "If Logins Exist should not return null"{
        Get-SuccessfulLogins | Should Not Be $null
    }
}