Function Get-AllTenantMFAUsers {
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
    . "$here\..\Get-TenantMFAUsers\Get-TenantMFAUsers.ps1"
    if ($Null -eq $TenantsList) {
        $session = Connect-Office365 -ConnectMSOLOnly
        $session | out-null
        $tenants = Get-MsolPartnerContract
    } Else {
        $tenants = $TenantsList
    }
    $mergedObject = @()

    
    foreach ($tenant in $tenants) {
        $mergedObject += Get-TenantMFAUsers -TenantDomainName $tenant.DefaultDomainName 
    }

    return $mergedObject
}