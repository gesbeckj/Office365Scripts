Function Get-AllTenantUserLicenses {
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$TenantsList,
        [pscredential]$credential
    )

    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $here = $PSScriptRoot
    }
    . "$here\..\Common\Connect-Office365.ps1"
    . "$here\..\Get-TenantUserLicenses\Get-TenantUserLicenses.ps1"
    if ($Null -eq $TenantsList) {
        $session = Connect-Office365 -ConnectMSOLOnly -credential $Credential
        $session | out-null
        $tenants = Get-MsolPartnerContract
    } Else {
        $tenants = $TenantsList
    }
    $mergedObject = @()
    if ($null -eq $credential){
    $DelegatedAdminCred = Get-Credential -Message "Enter delegated administrative credentials. This will not work with MFA"
    }
    else {
        $DelegatedAdminCred = $credential
    }

    
    foreach ($tenant in $tenants) {
        Write-Output $tenant.DefaultDomainName
        $mergedObject += Get-TenantUserLicenses -TenantDomainName $tenant.DefaultDomainName -DelegatedAdminCred $DelegatedAdminCred -TenantID $tenant.TenantID
    }

    return $mergedObject
}