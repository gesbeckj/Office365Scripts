[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Get-TenantMFAUsers.ps1"
. "$here\..\..\Common\Connect-TenantExchangeOnline.ps1"
. "$here\..\..\Common\Get-LicenseName.ps1"
. "$here\..\..\Common\Connect-Office365.ps1"
Describe "Get-TenantMFAUsers" {
    Function Get-MsolPartnerContract {}
    Function Get-MsolUser {}
    $StrongAuth = New-Object PSObject -Property @{
        State = "Enforced"
    }
    $UserOne = New-Object PSObject -Property @{
        Licenses    = "O365"
        StrongAuthenticationRequirements = $strongAuth
    }
    $WeakAuth = New-Object PSObject -Property @{
        State = "Disabled"
    }
    $UserTwo = New-Object PSObject -Property @{
        Licenses    = "O365"
        StrongAuthenticationRequirements = $WeakAuth
    }
    It "Script Should Exists" {
        (Test-Path "$here\..\Get-TenantMFAUsers.ps1") | Should Be $True
    }
    It "Should not throw"{
        {Get-TenantMFAUsers} | Should Not Throw
    }
    It "Should return one result if there is one MFA user"{
        Mock -CommandName Get-MSOLUser {Return $userOne}
        $Result = Get-TenantMFAUsers
        $Result | Should Not Be Null
    }
    It "Should return two results if there are two MFA users"{
        $Users = @()
        $Users += $userOne
        $users += $userTwo
        Mock -CommandName Get-MSOLUser {Return $users}
        $Result = Get-TenantMFAUsers
        $Result.count | Should Be 2
    }
}