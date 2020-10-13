Function Enable-TenantExchangeOnlineModernAuth {
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
        Write-Error "Connection to Office 365 Failed"
        throw "Unable to Connect to Office 365"
    }
    Import-PSSession -Session $session | Out-Null
    Set-OrganizationConfig -OAuth2ClientProfileEnabled $true
    if ((Get-OrganizationConfig).OAuth2ClientProfileEnabled -eq $false)
    {
        Write-Error "Unable to enable Modern Auth"
        return $false
    }
    return $true
}