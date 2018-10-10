$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Connect-Office365.ps1"
Import-Module MSOnline
Describe "Testing Connect-Office365"{
    It "Script Should Exists"{
        (Test-Path "$here\..\Connect-Office365.ps1") | Should Be $True
    }
    Context 'MSOnline Missing'{
        Mock -CommandName "Import-Module" {throw "Oops"}
        it 'Should return $Null if MSOnline Missing'{
            Connect-Office365 -ErrorAction SilentlyContinue | Should Be $Null
        }
    }
    Context 'Should Return'{
    $password = 'bogus' | ConvertTo-SecureString -AsPlainText -Force
    $cred = New-Object pscredential('bogus', $password)
    function Get-Credential { return $cred }
    Mock -CommandName New-PSSession {return "Session"}
    Mock -CommandName Connect-MsolService {return "Session"}
    It "Should not be Null normally"{
        Connect-Office365 | Should Not be $null
    }
}
}