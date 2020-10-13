Function Get-TenantAllUsers {
    [CmdletBinding()]
    param (
        [string]$TenantDomainName
    )
    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $here = $PSScriptRoot
    }
    $TenantID = Get-MsolPartnerContract -DomainName $TenantDomainName 
    $Users = get-msoluser -all -TenantId $TenantID.TenantID
    $Users | Add-member Tenant $TenantID.Name
    return $Users
}