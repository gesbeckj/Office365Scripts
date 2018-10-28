[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-TenantUserLicenses.ps1"
. "$here\..\..\Common\Connect-TenantExchangeOnline.ps1"
. "$here\..\..\Common\Get-LicenseName.ps1"
. "$here\..\..\Common\Connect-Office365.ps1"
Describe "Get-TenantUserLicenses" {
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
    $MailboxOne = New-Object PSObject -Propert @{
        UserPrincipalName    = "Test@Contoso.com"
        whenmailboxcreated   = Get-Date
        recipienttypedetails = 'SharedMailbox'
        primarysmtpaddress   = "Test@Contoso.com"
    }
    It "Script Should Exists" {
        (Test-Path "$here\..\Get-TenantUserLicenses.ps1") | Should Be $True
    }
    It 'Should throw if it cannot connect to Office 365' {

        Mock -Command Connect-TenantExchangeOnline {Return $null}
        {Get-TenantUserLicenses -ErrorAction SilentlyContinue } | Should Throw
    }
    It 'Should call Import-PSSession and Remove-PSSession Once' {

        Mock -Command Connect-TenantExchangeOnline {Return [System.Management.Automation.Runspaces.PSSession]}
        Mock -CommandName Import-PSSession {return 'Test'}
        Mock -CommandName Remove-PSSession {}
        $Result = Get-TenantUserLicenses 
        Assert-MockCalled -CommandName Import-PSSession -Exactly 1
        Assert-MockCalled -CommandName Remove-PSSession -Exactly 1
    }
    It 'Should call Get-Mailbox once' {
        Mock -Command Connect-TenantExchangeOnline {Return [System.Management.Automation.Runspaces.PSSession]}
        Mock -CommandName Get-Mailbox {}
        $Result = Get-TenantUserLicenses 
        Assert-MockCalled -CommandName Get-Mailbox -Exactly 1
    }
    It 'Should return one one result if one mailbox exists' {
        Mock -Command Get-MsolUser {}
        Function Get-LicenseName {
        }
        Function Get-MsolPartnerContract {
            return "Contoso Corp"
        }
        Mock -CommandName Get-Mailbox {Return $MailboxOne}
        $Result = Get-TenantUserLicenses
        $Result | Should Not Be Null
    }
    It 'Should return two results if two mailboxes exist' {
        Mock -Command Get-MsolUser {}
        Function Get-LicenseName {
        }
        Function Get-MsolPartnerContract {
            return "Contoso Corp"
        }
        $mailboxes = @()
        $mailboxes += $MailboxOne
        $mailboxes += $MailboxOne
        Mock -CommandName Get-Mailbox {Return $mailboxes}
        $Result = Get-TenantUserLicenses
        $Result.count | Should Be 2
    }
}