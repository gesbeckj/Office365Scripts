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
            (. $here\..\Disable-ExchangeOnlineIMAP.ps1) | Should Be 0
        }
    }
    Context "Return 1 if CAS Mailbox Plan or a mailboxes has IMAP & POP enabled"{
        It "Should return 1 if IMAP / POP are enabled on one mailbox"{
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
            (. $here\..\Disable-ExchangeOnlineIMAP.ps1) | Should Be 1
        }
        It "Should return 1 if IMAP / POP are enabled on CAS mailbox plan"{
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
            (. $here\..\Disable-ExchangeOnlineIMAP.ps1) | Should Be 1
        }
    }
}