Function Get-TenantMFAUsers
{
    [CmdletBinding()]
    param (
        [string]$TenantDomainName
    )
    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    else {
        $here = $PSScriptRoot
    }
    $TenantID = Get-MsolPartnerContract -DomainName $TenantDomainName | Select-Object TenantId
    $UsersStatus = get-msoluser -TenantId $TenantID.TenantID | Where-Object {$_.Licenses -ne $null}| select userprincipalname, @{N="MFAStatus"; E={ if( $_.StrongAuthenticationRequirements.State -ne $null){ $_.StrongAuthenticationRequirements.State} else { "Disabled"}}}, @{N="Tenant"; E={$TenantDomainName}}
    return $UsersStatus
}