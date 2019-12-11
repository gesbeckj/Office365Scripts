function Connect-TenantExchangeOnline {
    [CmdletBinding()]
    param(
        [string]$TenantDomainName,
        [string]$ExchangeRefreshToken,
        [string]$UPN
    )
    #Attempt to Import the MSOnline Module
    try {
        Import-Module MSOnline
    } catch {
        Write-Error "Unable to Load MSOnline Module. Try running Install-Module MSonline"
        return $null
    }
    Write-Output $TenantDomainName
    Write-Output $ExchangeRefreshToken
    Write-Output $UPN
    $token = New-PartnerAccessToken -ApplicationId 'a0c73c16-a7e3-4564-9a95-2bdf47383716'-RefreshToken $ExchangeRefreshToken -Scopes 'https://outlook.office365.com/.default' -Tenant $TenantDomainName
    $tokenValue = ConvertTo-SecureString "Bearer $($token.AccessToken)" -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($upn, $tokenValue)
    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.outlook.com/powershell-liveid?DelegatedOrg=$($TenantDomainName)&amp;BasicAuthToOAuthConversion=true" -Credential $credential -Authentication Basic -AllowRedirection
    return $Session
}       
