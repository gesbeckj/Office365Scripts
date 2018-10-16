Function Get-AllTenantSuccessfulLogins {
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$TenantsList
    )
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    . "$here\..\Common\Connect-Office365.ps1"
    . "$here\..\Get-TenantSuccessfulLogins\Get-TenantSuccessfulLogins.ps1"
    if ($Null -eq $TenantsList) {
        $session = Connect-Office365 -ConnectMSOLOnly
        $session | out-null
        $tenants = Get-MsolPartnerContract
    }
    Else {
        $tenants = $TenantsList
    }
    $DelegatedAdminCred = Get-Credential -Message "Enter delegated administrative credentials. This will not work with MFA"
    $mergedObject = @()

    foreach ($tenant in $tenants) {
        $mergedObject += Get-TenantSuccessfulLogins -TenantDomainName $tenant.DefaultDomainName -DelegatedAdminCred $DelegatedAdminCred
    }
}