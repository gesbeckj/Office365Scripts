Function Enable-AllTenantsExchangeOnlineModernAuth {
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$TenantsList
    )

    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $here = $PSScriptRoot
    }
    . "$here\..\Common\Connect-Office365.ps1"
    . "$here\..\Enable-TenantExchangeOnlineModernAuth\Enable-TenantExchangeOnlineModernAuth.ps1"
    if ($Null -eq $TenantsList) {
        $session = Connect-Office365 -ConnectMSOLOnly
        $session | out-null
        $tenants = Get-MsolPartnerContract
    } Else {
        $tenants = $TenantsList
    }
    $DelegatedAdminCred = Get-Credential -Message "Enter delegated administrative credentials. This will not work with MFA"
    foreach ($tenant in $tenants) {
        Enable-TenantExchangeOnlineModernAuth -TenantDomainName $tenant.DefaultDomainName -DelegatedAdminCred $DelegatedAdminCred
    }
}