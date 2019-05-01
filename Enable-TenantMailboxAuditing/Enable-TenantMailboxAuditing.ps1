Function Enable-TenantMailboxAuditing {
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
        #throw "Unable to Connect to Office 365"
    }
    Import-PSSession -Session $session
    #Enable Auditing
#Check global status.
$audit_status = Get-OrganizationConfig | select-object AuditDisabled
Write-Information "Organizational audit status: $audit_status" -InformationAction Continue

#Iterate through all mailboxes and set the default audit properites as defined by Microsoft. This also resets inheritance so to automatically include any new audit flags added by Microsoft in the future.
#This sets all mailboes - when setting unique audiing values, there is a restricted set of mailbox types that can accept altered criteria - user, group, shared, and team.
Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox,SharedMailbox,GroupMailbox,TeamMailbox | Set-Mailbox -AuditEnabled $true -AuditOwner MailboxLogin,HardDelete,SoftDelete,Update,Move -AuditDelegate SendOnBehalf,MoveToDeletedItems,Move -AuditAdmin Copy,MessageBind


    Write-Information "Auding enabled for $tenantDomainName" -InformationAction Continue
    Remove-PSSession $session
}