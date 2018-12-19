Function Get-TenantUserLicenses {
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
    $outputsession = Import-PSSession -Session $session -WarningAction SilentlyContinue
    $outputsession | Out-Null
    Write-Verbose "Getting mailbox information....this may take some time."
    $mailboxes = get-mailbox -ResultSize Unlimited | Where-Object {$_.DisplayName -notlike "Discovery Search Mailbox"} 
    Remove-PSSession $session
    Write-Verbose "Mailbox information gathered"
    $outputData = @()
    foreach ($mailbox in $mailboxes) {
        write-verbose $mailbox.userprincipalname
        try{
        $licenseParts = ((Get-MsolUser -UserPrincipalName $mailbox.userprincipalname -TenantId $TenantID -ErrorAction ignore).licenses.AccountSku.SkuPartNumber)
        }
        Catch {
            $licenseParts = $Null
        }
        $userLicense = Get-LicenseName -LicenseParts $licenseParts
        $upn = $mailbox.userprincipalname 
        $whencreated = $mailbox.whenmailboxcreated 
        $type = $mailbox.recipienttypedetails
        $smtp = $mailbox.primarysmtpaddress 
        $company = Get-MsolPartnerContract -DomainName $tenantDomainname
        $data = New-Object PSObject -Property @{
            UPN       = $UPN
            SMTP      = $SMTP
            Created   = $whencreated
            Type      = $type
            LastLogin = $lastlogon
            License   = $userLicense
            Tenant    = $company.Name
        }
        $outputData += $data
    }
    return $outputData
}