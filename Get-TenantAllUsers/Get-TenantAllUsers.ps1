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
    $TenantID = Get-MsolPartnerContract -DomainName $TenantDomainName | Select-Object TenantId
    $Users = get-msoluser -all -TenantId $TenantID.TenantID
    return $Users
}