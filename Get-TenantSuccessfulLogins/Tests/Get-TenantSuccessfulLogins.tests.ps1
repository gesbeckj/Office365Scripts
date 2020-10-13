[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-TenantSuccessfulLogins.ps1"

Describe "Get-TenantSuccessfulLogins" {
    Function Get-TenantOffice365AuditLogs {}
    function Search-unifiedAuditLog {}
    function Remove-PSSession {
    }
    function New-PSSession {
    }
    function Import-PSSession {
        return 'Test'
    }
    $password = 'bogus' | ConvertTo-SecureString -AsPlainText -Force
    $cred = New-Object pscredential('bogus', $password)
    function Get-Credential {
        return $cred 
    }
    It "Script Should Exists" {
        (Test-Path "$here\..\Get-TenantSuccessfulLogins.ps1") | Should Be $True
    }
    It "Should not throw"{
        {Get-TenantSuccessfulLogins -DelegatedAdminCred $cred} | Should Not Throw
    }
}