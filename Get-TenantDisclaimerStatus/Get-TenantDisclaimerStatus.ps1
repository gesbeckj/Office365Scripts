Function Get-TenantDisclaimerStatus {
    [CmdletBinding()]
    param (
        [string]$TenantDomainName,
        [string]$ExchangeRefreshToken,
        [string]$UPN
    )
    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $here = $PSScriptRoot
    }
    . "$here\..\Common\Connect-TenantExchangeOnline.ps1"
    . "$here\..\Common\Connect-Office365.ps1"
    $session = Connect-TenantExchangeOnline -TenantDomainName $TenantDomainName -UPN $UPN -ExchangeRefreshToken $ExchangeRefreshToken
    if ($null -eq $session) {
        Write-Error "Connection to Office 365 Failed"
        $session = Connect-TenantExchangeOnline -TenantDomainName $TenantDomainName -UPN $UPN -ExchangeRefreshToken $ExchangeRefreshToken
        if ($null -eq $session){
            return $false
        }
    }
    $ImportSession = Import-PSSession -Session $session
    $ImportSession | Out-Null
    $DisclaimerRules = Get-TransportRule | Where-Object {$_.State -eq "Enabled" -and $_.Mode -eq "Enforce" -and $_.FromScope -eq "NotInOrganization" -and `
    $_.actions -eq "Microsoft.Exchange.MessagingPolicies.Rules.Tasks.ApplyHtmlDisclaimerAction" -and $null -eq $_.ExceptIfSenderDomainIs}
    Remove-PSSession -Session $session
    if ($null -eq $DisclaimerRules) {
        return $false
    } else {
        return $true
    }

}