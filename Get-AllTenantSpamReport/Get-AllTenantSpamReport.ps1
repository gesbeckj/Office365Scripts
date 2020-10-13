Function Get-AllTenantSpamReport {
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$TenantsList,
        [pscredential]$DelegatedAdminCred
    )

    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $here = $PSScriptRoot
    }
    . "$here\..\Common\Connect-Office365.ps1"
    . "$here\..\Get-TenantSpamReport\Get-TenantSpamReport.ps1"
    if ($Null -eq $TenantsList) {

        $session = Connect-Office365 -ConnectMSOLOnly
        $session | out-null
        $tenants = Get-MsolPartnerContract
    } Else {
        $tenants = $TenantsList
    }
    if ($null -eq $DelegatedAdminCred)
    {    $DelegatedAdminCred = Get-Credential -Message "Enter delegated administrative credentials. This will not work with MFA"}

    $mergedObject = @()
    foreach ($tenant in $tenants) {
        $result = Get-TenantSpamReport -DelegatedAdminCred $DelegatedAdminCred -TenantDomainName $tenant.DefaultDomainName
        $result | Add-member TenantName $Tenant.Name
        
        $mergedObject += $result
    }
    return $mergedObject
}