[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

. "$here\.\Get-SuccessfulLogins.ps1"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Describe "Testing Get-SuccessfulLogins"{
    It "Script Should Exists"{
        (Test-Path "$here\..\Get-SuccessfulLogins.ps1") | Should Be $True
    }
    It "Should not throw"{
        {Get-IMAPLogins} | Should Not Throw
    }
    It "If no logins exists should return null"{
        Get-IMAPLogins | Should Be $null
    }
    It "If Logins Exist should not return null"{
        Get-IMAPLogins | Should Not Be $null
    }
}