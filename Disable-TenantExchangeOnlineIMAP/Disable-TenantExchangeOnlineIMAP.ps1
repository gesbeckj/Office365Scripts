Function Disable-TenantExchangeOnlineIMAP {
    [CmdletBinding()]
    param (
        [string]$TenantDomainName,
        [pscredential]$DelegatedAdminCred
    )
    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $here = $PSScriptRoot
    }

    . "$here\..\Common\Connect-TenantExchangeOnline.ps1"
    $session = Connect-TenantExchangeOnline -TenantDomainName $TenantDomainName -DelegatedAdminCred $DelegatedAdminCred
    if ($null -eq $session) {
        Write-Error "Connection to Office 365 Failed for $TenantDomainName"
    }
    Import-PSSession -Session $session
    #Disable IMAP & POP in CAS Mailbox Plans
    Get-CASMailboxPlan -Filter 'ImapEnabled -eq "true" -or PopEnabled -eq "true" ' | set-CASMailboxPlan -ImapEnabled $false -PopEnabled $false

    #Verify this was successful.
    $Results = Get-CASMailboxPlan -Filter '{ImapEnabled -eq "true" -or PopEnabled -eq "true"'
    if ($null -ne $Results) {
        Write-Error "Unable to Disable IMAP and POP in CAS Mailbox Plans for $TenantDomainname"
    }

    #Disable IMAP & POP on existing Mailboxes
    Get-CASMailbox -Filter 'ImapEnabled -eq "true" -or PopEnabled -eq "true" ' | Select-Object @{n = "Identity"; e = {$_.primarysmtpaddress}} | Set-CASMailbox -ImapEnabled $false -PopEnabled $false
    $Results = Get-CASMailbox -Filter 'ImapEnabled -eq "true" -or PopEnabled -eq "true"'
    if ($null -ne $Results) {
        Write-Error "Unable to Disable IMAP and POP on all existing mailboxes for $TenantDomainname"
    }
    Write-Information "IMAP / POP are fully disabled for $TenantDomainname"
    Remove-PSSession $session
}