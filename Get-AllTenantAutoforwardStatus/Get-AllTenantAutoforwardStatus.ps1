Function Get-AllTenantAutoforwardStatus {
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$TenantsList

    )

    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    else {
        $here = $PSScriptRoot
    }
    . "$here\..\Common\Connect-Office365.ps1"
    . "$here\..\Get-TenantAutoforwardStatus\Get-TenantAutoforwardStatus.ps1"
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
    foreach  ($tenant in $tenants) {
        $AutoForwardBlocked = Get-TenantAutoforwardStatus -DelegatedAdminCred $DelegatedAdminCred -TenantDomainName $tenant.DefaultDomainName
        $data = New-Object PSObject -Property @{
            Tenant = $Tenant.Name
            AutoForwardBlocked = $AutoForwardBlocked
        }
        $mergedObject += $data
    }
    return $mergedObject
}