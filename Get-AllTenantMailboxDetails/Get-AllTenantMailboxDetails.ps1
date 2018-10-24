Function Get-AllTenantMailboxDetails {
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
    . "$here\..\Get-TenantMailboxDetails\Get-TenanMailboxDetails.ps1"
    if ($Null -eq $TenantsList) {
        $session = Connect-Office365 -ConnectMSOLOnly
        $session | out-null
        $tenants = Get-MsolPartnerContract
    } Else {
        $tenants = $TenantsList
    }
    $mergedObject = @()
    $DelegatedAdminCred = Get-Credential -Message "Enter delegated administrative credentials. This will not work with MFA"

    
    foreach ($tenant in $tenants) {
        $mergedObject += Get-TenantMailboxDetails -TenantDomainName $tenant.DefaultDomainName -DelegatedAdminCred $DelegatedAdminCred -TenantID $tenant.TenantID
    }

    return $mergedObject
}