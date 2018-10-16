function Connect-TenantExchangeOnline {
    [CmdletBinding()]
    param(
        [string]$TenantDomainName,
        [pscredential]$DelegatedAdminCred
    )
    #Attempt to Import the MSOnline Module
    try {
        Import-Module MSOnline
    }
    catch {
        Write-Error "Unable to Load MSOnline Module. Try running Install-Module MSonline"
        return $null
    }
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.outlook.com/powershell-liveid?DelegatedOrg=$TenantDomainName" -Credential $DelegatedAdminCred -Authentication Basic -AllowRedirection
    return $Session
}       
