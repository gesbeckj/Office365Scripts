Function Get-TenantATPReport {
    [CmdletBinding()]
    param (
        [string]$TenantDomainName,
        [pscredential]$DelegatedAdminCred
    )
    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $here = $PSScriptRoot
    }
    . "$here\..\Common\Connect-TenantExchangeOnline.ps1"
    . "$here\..\Common\Connect-Office365.ps1"
    $session = Connect-TenantExchangeOnline -TenantDomainName $TenantDomainName -DelegatedAdminCred $DelegatedAdminCred
    if ($null -eq $session) {
        Write-Error "Connection to Office 365 Failed"
        throw "Unable to Connect to Office 365"
    }
    $ImportSession = Import-PSSession -Session $session
    $ImportSession | Out-Null

    $results = Get-MailTrafficATPReport -StartDate (get-date).AddDays(-30) -end (get-date)
    
    Remove-PSSession -Session $session

    return $results

}