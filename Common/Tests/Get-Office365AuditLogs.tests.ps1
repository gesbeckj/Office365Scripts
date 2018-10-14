[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-Office365AuditLogs.ps1"
Import-Module MSOnline
Describe "Testing Get-Office365AuditLogs"{
    $password = 'bogus' | ConvertTo-SecureString -AsPlainText -Force
    $cred = New-Object pscredential('bogus', $password)
    function Get-Credential { return $cred }
    Mock -CommandName New-PSSession {return "Session"}
    Mock -CommandName Connect-MsolService {return "Session"}
    Mock -CommandName Remove-PSSession {}
    It 'Null should be returned if no audit logs exist'{
        function Search-unifiedAuditLog {}
        Function Import-PSSession {}
        Get-Office365AuditLogs | Should Be $Null
        }
        
    It 'Null should not be returned if audit logs exist'{
        function Search-unifiedAuditLog {"T"}
        Function Import-PSSession {}
        Get-Office365AuditLogs | Should Not Be $Null
        }
    It 'Get-Office365AuditLogs should not throw'{
        function Search-unifiedAuditLog {}
        Function Import-PSSession {}
        {Get-Office365AuditLogs} | Should Not Throw
        }
}