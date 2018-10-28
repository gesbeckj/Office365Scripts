[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-TenantAutoforwardStatus.ps1"
. "$here\..\..\Common\Connect-TenantExchangeOnline.ps1"
. "$here\..\..\Common\Get-LicenseName.ps1"
. "$here\..\..\Common\Connect-Office365.ps1"
Describe "Get-TenantAutoforwardStatus" {
    function Remove-PSSession {
    }
    function Import-PSSession {
        return 'Test'
    }
    function Get-Mailbox {
    }
    function Get-MsolUser {
    }
    $password = 'bogus' | ConvertTo-SecureString -AsPlainText -Force
    $cred = New-Object pscredential('bogus', $password)
    function Get-Credential {
        return $cred 
    }
    $RuleOne = New-Object PSObject -Propert @{
        MessageTypeMatches              = "AutoForward"
        State                           = "Enabled"
        Mode                            = "Enforce"
        FromScope                       = "InOrganization"
        SentToScope                     = "NotInOrganization"
        RejectMessageEnhancedStatusCode = "5.7.1"
    }
    function Get-TransportRule {
        
    }
    It "Script Should Exists" {
        (Test-Path "$here\..\Get-TenantAutoforwardStatus.ps1") | Should Be $True
    }
    It 'Should throw if it cannot connect to Office 365' {

        Mock -Command Connect-TenantExchangeOnline {Return $null}
        {Get-TenantAutoforwardStatus -ErrorAction SilentlyContinue } | Should Throw
    }
    It 'Should call Import-PSSession and Remove-PSSession Once' {

        Mock -Command Connect-TenantExchangeOnline {Return [System.Management.Automation.Runspaces.PSSession]}
        Mock -CommandName Import-PSSession {return 'Test'}
        Mock -CommandName Remove-PSSession {}
        $Result = Get-TenantAutoforwardStatus
        Assert-MockCalled -CommandName Import-PSSession -Exactly 1
        Assert-MockCalled -CommandName Remove-PSSession -Exactly 1
    }
    It 'Should return true if a transport rule exists that blocks autoforwards' {
        Mock -Command Connect-TenantExchangeOnline {Return [System.Management.Automation.Runspaces.PSSession]}
        Mock -CommandName Import-PSSession {return 'Test'}
        Mock -CommandName Remove-PSSession {}
        Mock -CommandName Get-TransportRule {return $RuleOne}
        $Result = Get-TenantAutoforwardStatus
        $Result | Should Be $True
    }
    It 'Should return false if no transport rule exists that blocks autoforwards'{
        Mock -Command Connect-TenantExchangeOnline {Return [System.Management.Automation.Runspaces.PSSession]}
        Mock -CommandName Import-PSSession {return 'Test'}
        Mock -CommandName Remove-PSSession {}
        Mock -CommandName Get-TransportRule {return $null}
        $Result = Get-TenantAutoforwardStatus
        $Result | Should Be $False
    }
}