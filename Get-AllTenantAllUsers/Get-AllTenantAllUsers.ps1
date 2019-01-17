Function Get-AllTenantAllUsers {
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$TenantsList,
        [pscredential]$Credential
    )

    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $here = $PSScriptRoot
    }
    . "$here\..\Common\Connect-Office365.ps1"
    . "$here\..\Get-TenantALLUsers\Get-TenantALLUsers.ps1"
    if ($Null -eq $TenantsList) {
        $session = Connect-Office365 -ConnectMSOLOnly -credential $credential
        $session | out-null
        $tenants = Get-MsolPartnerContract
    } Else {
        $tenants = $TenantsList
    }
    $mergedObject = @()

    
    foreach ($tenant in $tenants) {
        $mergedObject += Get-TenantALLUsers -TenantDomainName $tenant.DefaultDomainName 
    }

    return $mergedObject
}