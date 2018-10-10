$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Describe "Testing Disable-ExchangeOnlineIMAP"{
    It "Script Should Exists"{
        (Test-Path "$here\..\Disable-ExchangeOnlineIMAP.ps1") | Should Be $True
    }    
}