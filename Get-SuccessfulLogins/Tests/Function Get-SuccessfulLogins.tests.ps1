[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

. "$here\..\Get-IMAPLogins.ps1"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Describe "Testing Get-IMAPLogins"{
    It "Script Should Exists"{
        (Test-Path "$here\..\Get-IMAPLogins.ps1") | Should Be $True
    }
    It "Should not throw"{
        {Get-IMAPLogins} | Should Not Throw
    }
    It "If no IMAP logins exists should return null"{
        Get-IMAPLogins | Should Be $null
    }
    It "If IMAP Logins Exist should not return null"{
        Get-IMAPLogins | Should Not Be $null
    }
}