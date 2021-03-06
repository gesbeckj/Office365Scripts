[CmdletBinding()]
param ()
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$here\..\Common\Connect-Office365.ps1"
$session = Connect-Office365
if ($null -eq $session) {
    Write-Error "Connection to Office 365 Failed"
    throw "Unable to Connect to Office 365"
}
Import-PSSession -Session $session
#Disable IMAP & POP in CAS Mailbox Plans
Get-CASMailboxPlan -Filter 'ImapEnabled -eq "true" -or PopEnabled -eq "true" ' | set-CASMailboxPlan -ImapEnabled $false -PopEnabled $false

#Verify this was successful.
$Results = Get-CASMailboxPlan -Filter 'ImapEnabled -eq "true" -or PopEnabled -eq "true"'
if ($null -ne $Results) {
    Throw "Unable to Disable IMAP and POP in CAS Mailbox Plans"
}

#Disable IMAP & POP on existing Mailboxes
Get-CASMailbox -Filter 'ImapEnabled -eq "true" -or PopEnabled -eq "true" ' | Select-Object @{n = "Identity"; e = {$_.primarysmtpaddress}} | Set-CASMailbox -ImapEnabled $false -PopEnabled $false
$Results = Get-CASMailbox -Filter 'ImapEnabled -eq "true" -or PopEnabled -eq "true"'
if ($null -ne $Results) {
    Throw "Unable to Disable IMAP and POP on all existing mailboxes."
}
Write-Information "IMAP / POP are fully disabled"
return 0