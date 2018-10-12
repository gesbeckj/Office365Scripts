[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Describe "Testing Disable-ExchangeOnlineIMAP"{
    It "Script Should Exists"{
        (Test-Path "$here\..\Disable-ExchangeOnlineIMAP.ps1") | Should Be $True
    }    
    Context "Return 0 if both CAS Mailbox Plan and all Mailboxes have IMAP & POP disabled"{
        It "Should return 0 if IMAP / POP are disabled"{
            #Function Connect-Office365 {Return "Session"}
            Function Import-PSSession {}
            Function Connect-MSOLService {}
            Function New-PSSession {"Session"}
            Function set-CASMailboxPlan {}
            Function set-CASMailbox {}
            Function Get-CASMailboxPlan {}
            Function Get-CASMailbox {}
            $password = 'bogus' | ConvertTo-SecureString -AsPlainText -Force
            $cred = New-Object pscredential('bogus', $password)
            function Get-Credential { return $cred } 
            (. $here\..\Disable-ExchangeOnlineIMAP.ps1) | Should -Be 0
        }
    }
    Context "Throw if CAS Mailbox Plan or a mailboxes has IMAP & POP enabled"{
        It "Should return throw if IMAP / POP are enabled on one mailbox"{
            #Function Connect-Office365 {Return "Session"}
            Function Import-PSSession {}
            Function Connect-MSOLService {}
            Function New-PSSession {"Session"}
            Function set-CASMailboxPlan {}
            Function set-CASMailbox {}
            Function Get-CASMailboxPlan {}
            Function Get-CASMailbox {"Mailbox"}
            $password = 'bogus' | ConvertTo-SecureString -AsPlainText -Force
            $cred = New-Object pscredential('bogus', $password)
            function Get-Credential { return $cred } 
            {(. $here\..\Disable-ExchangeOnlineIMAP.ps1 -ErrorAction SilentlyContinue)} | Should Throw
        }
        It "Should throw if IMAP / POP are enabled on CAS mailbox plan"{
            #Function Connect-Office365 {Return "Session"}
            Function Import-PSSession {}
            Function Connect-MSOLService {}
            Function New-PSSession {"Session"}
            Function set-CASMailboxPlan {}
            Function set-CASMailbox {}
            Function Get-CASMailboxPlan {"Plan"}
            Function Get-CASMailbox {}
            $password = 'bogus' | ConvertTo-SecureString -AsPlainText -Force
            $cred = New-Object pscredential('bogus', $password)
            function Get-Credential { return $cred } 
            {(. $here\..\Disable-ExchangeOnlineIMAP.ps1 -ErrorAction SilentlyContinue)} | Should Throw
        }
    }
    It "Should throw if no Office 365 session exists"{
        Function Import-PSSession {}
        Function Connect-MSOLService {}
        Function New-PSSession {$null}
        $password = 'bogus' | ConvertTo-SecureString -AsPlainText -Force
        $cred = New-Object pscredential('bogus', $password)
        function Get-Credential { return $cred } 
        {(. $here\..\Disable-ExchangeOnlineIMAP.ps1 -ErrorAction SilentlyContinue)} | Should Throw
    }
    It "Should throw if Import-PSSession throws"{
        Function Import-PSSession {throw "PSSession Failure"}
        Function Connect-MSOLService {}
        Function New-PSSession {"Session"}
        $password = 'bogus' | ConvertTo-SecureString -AsPlainText -Force
        $cred = New-Object pscredential('bogus', $password)
        function Get-Credential { return $cred } 
        {(. $here\..\Disable-ExchangeOnlineIMAP.ps1 -ErrorAction SilentlyContinue)} | Should Throw
    }
}