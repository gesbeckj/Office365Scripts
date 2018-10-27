[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Connect-Office365.ps1"
Import-Module MSOnline
Describe "Connect-Office365" {
    It "Script Should Exists" {
        (Test-Path "$here\..\Connect-Office365.ps1") | Should Be $True
    }
    it 'Should return $Null if MSOnline Missing' {
        Mock -CommandName "Import-Module" {throw "Oops"}
        Connect-Office365 -ErrorAction SilentlyContinue | Should Be $Null
    }
    It 'Should not return $Null' {
        $password = 'bogus' | ConvertTo-SecureString -AsPlainText -Force
        $cred = New-Object pscredential('bogus', $password)
        function Get-Credential {
            return $cred 
        }
        Mock -CommandName "Import-Module" {}
        Mock -CommandName New-PSSession {return 'Test'}
        Mock -CommandName Connect-MsolService {}
        Connect-Office365 | Should Be 'Test'
    }
}