Function Get-TenantMailboxDetails {
    [CmdletBinding()]
    param (
        [string]$TenantDomainName,
        [string]$TenantID,
        [pscredential]$DelegatedAdminCred
    )
    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $here = $PSScriptRoot
    }
    . "$here\..\Common\Connect-TenantExchangeOnline.ps1"
    . "$here\..\Common\Get-LicenseName.ps1"
    . "$here\..\Common\Connect-Office365.ps1"
    #$msolSession = Connect-Office365 -ConnectMSOLOnly
    #$msolSession | Out-Null
    $session = Connect-TenantExchangeOnline -TenantDomainName $TenantDomainName -DelegatedAdminCred $DelegatedAdminCred
    if ($null -eq $session) {
        Write-Error "Connection to Office 365 Failed"
        throw "Unable to Connect to Office 365"
    }
    Import-PSSession -Session $session
    Write-Verbose "Getting mailbox information....this may take some time."
    $mailboxes = get-mailbox -ResultSize Unlimited | Where-Object {$_.DisplayName -notlike "Discovery Search Mailbox"} 

    Write-Verbose "Mailbox information gathered"
    $outputData = @()
    foreach ($mailbox in $mailboxes) {
        write-verbose $mailbox.userprincipalname
        $licenseParts = ((Get-MsolUser -UserPrincipalName $mailbox.userprincipalname -TenantId $TenantID).licenses.AccountSku.SkuPartNumber)
        $userLicense = Get-LicenseName -LicenseParts $licenseParts
        $upn = $mailbox.userprincipalname 
        $whencreated = $mailbox.whenmailboxcreated 
        $type = $mailbox.recipienttypedetails
        $smtp = $mailbox.primarysmtpaddress 
        Write-Verbose "E-mail address detected as $smtp"
        $statistics = get-mailboxstatistics -identity "$smtp"
        $lastlogon = $statistics.lastlogontime 
        if ($lastlogon -eq $null) { 
            $lastlogon = "Never Logged In" 
            Write-Verbose "User has never logged in"
        }
        $company = Get-MsolPartnerContract -DomainName $tenantDomainname
        $data = New-Object PSObject -Property @{
            UPN       = $UPN
            SMTP      = $SMTP
            Created   = $whencreated
            Type      = $type
            LastLogin = $lastlogon
            License   = $userLicense
            Tenant    = $company.name
        }
        $outputData += $data
    }
    Remove-PSSession $session
    return $outputData
}