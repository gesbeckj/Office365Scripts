[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-TenantOffice365AuditLogs.ps1"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Describe "Get-TenantOffice365AuditLogs" {
    function Remove-PSSession {
    }
    function Import-PSSession {
        return 'Test'
    }
    function Connect-TenantExchangeOnline {}
    function Search-unifiedAuditLog {}
    It "Script Should Exists" {
        (Test-Path "$here\..\Get-TenantOffice365AuditLogs.ps1") | Should Be $True
    }
    It "Should call Import-PSSession and Remove-PSSession Once"{
        Mock -Command Connect-TenantExchangeOnline {Return [System.Management.Automation.Runspaces.PSSession]}
        Mock -CommandName Import-PSSession {return 'Test'}
        Mock -CommandName Remove-PSSession {}
        $Result = Get-TenantOffice365AuditLogs 
        Assert-MockCalled -CommandName Import-PSSession -Exactly 1
        Assert-MockCalled -CommandName Remove-PSSession -Exactly 1
    }
    It "Should return null if there are no logs"{
        Mock -Command Connect-TenantExchangeOnline {Return [System.Management.Automation.Runspaces.PSSession]}
        Mock -CommandName Import-PSSession {return 'Test'}
        Mock -CommandName Remove-PSSession {}
        $Result = Get-TenantOffice365AuditLogs 
        $Result | Should Be $Null
    }
    It "Should not return null if there are no logs"{
        Mock -Command Connect-TenantExchangeOnline {Return [System.Management.Automation.Runspaces.PSSession]}
        Mock -CommandName Import-PSSession {return 'Test'}
        Mock -CommandName Remove-PSSession {}
        Mock -CommandName Search-unifiedAuditLog {return "data"}
        $Result = Get-TenantOffice365AuditLogs 
        $Result | Should Not Be Null
    }

}