 [CmdletBinding()]
param ()
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Output $here
. "$PSCommandPath\..\Common\Connect-Office365.ps1"
$session = Connect-Office365
if ($null -eq $session)
{
    Write-Error "Connection to Office 365 Failed"
}
try {
    Import-Session
}
catch {
    Write-Error "Unable to Import PSSession"
    throw "Unable to Connect to Office 365"
}
Import-PSSession -Session $session

#Disable IMAP & POP in CAS Mailbox Plans
Get-CASMailboxPlan -Filter {ImapEnabled -eq "true" -or PopEnabled -eq "true" } | set-CASMailboxPlan -ImapEnabled $false -PopEnabled $false

#Verify this was successful.
$Results = Get-CASMailboxPlan -Filter {ImapEnabled -eq "true" -or PopEnabled -eq "true" }
if ($null -ne $Results)
{
    Write-Error -Message "Unable to Disable IMAP and POP in CAS Mailbox Plans"
    return 1
}

#Disable IMAP & POP on existing Mailboxes
Get-CASMailbox -Filter {ImapEnabled -eq "true" -or PopEnabled -eq "true" } | Select-Object @{n = "Identity"; e = {$_.primarysmtpaddress}} | Set-CASMailbox -ImapEnabled $false -PopEnabled $false
$Results = Get-CASMailbox -Filter {ImapEnabled -eq "true" -or PopEnabled -eq "true" }
if ($null -ne $Results)
{
    Write-Error -Message "Unable to Disable IMAP and POP on all existing mailboxes. Failed mailboxes:"
    Write-Error -Message $Results
    return 1
}
return 0