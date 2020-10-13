Function Get-TenantAutoforwardStatus {
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
        $session = Connect-TenantExchangeOnline -TenantDomainName $TenantDomainName -UPN $UPN -ExchangeRefreshToken $ExchangeRefreshToken
        if ($null -eq $session){
            return $false
        }
    }
    $ImportSession = Import-PSSession -Session $session
    $ImportSession | Out-Null
    $AutoforwardRules = Get-TransportRule | Where-Object {$_.MessageTypeMatches -eq "AutoForward" -and $_.State -eq "Enabled" -and $_.Mode -eq "Enforce" -and $_.FromScope -eq "InOrganization" -and $_.SentToScope -eq "NotInOrganization" -and $_.RejectMessageEnhancedStatusCode -eq "5.7.1"}
    Remove-PSSession -Session $session
    if ($null -eq $AutoforwardRules) {
        return $false
    } else {
        return $true
    }

}