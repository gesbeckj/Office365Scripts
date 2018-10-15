[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-SuccessfulLogins.ps1"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-Office365AuditLogs.ps1"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Describe "Testing Get-SuccessfulLogins"{
    It "Script Should Exists"{
        (Test-Path "$here\Get-SuccessfulLogins.ps1") | Should Be $True
    }
    It "Should not throw"{
        Mock -CommandName Get-Office65AuditLogs -MockWith {Return $null}
        {Get-SuccessfulLogins} | Should Not Throw
    }
    It "If no logins exists should return null"{
        Mock -CommandName Get-Office65AuditLogs -MockWith {Return $null}
        Get-SuccessfulLogins | Should Be $null
    }
    #It "If Logins Exist should not return null"{
    #    Mock -CommandName Get-Office65AuditLogs -MockWith {Return "Test"}
    #    Get-SuccessfulLogins | Should Not Be $null
    #}
}