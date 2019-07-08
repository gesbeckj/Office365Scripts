Function Get-AllTenantGraphAPIData {
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$TenantsList,
        [pscredential]$DelegatedAdminCred,
        [string]$URI,
        [string]$refreshToken,
        [string]$tenantID
    )

    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $here = $PSScriptRoot
    }
    . "$here\..\Get-TenantGraphAPIData\Get-TenantGraphAPIData.ps1"
    if ($Null -eq $TenantsList) {
        Import-Module AzureAD
        $azureToken = New-PartnerAccessToken -RefreshToken $refreshToken -Resource https://management.azure.com/ -Credential $DelegatedAdminCred -TenantId $tenantID
        $graphToken =  New-PartnerAccessToken -RefreshToken $refreshToken -Resource https://graph.microsoft.com -Credential $DelegatedAdminCred -TenantId $tenantID
        $TempResult = Connect-AzureRmAccount -AccessToken $azureToken.AccessToken -GraphAccessToken $graphToken.AccessToken -TenantId $tenantID
        $tenants = Get-AzureADContract -All $true
    } Else {
        $tenants = $TenantsList
    }
    if ($null -eq $DelegatedAdminCred)
    {    $DelegatedAdminCred = Get-Credential -Message "Enter delegated administrative credentials. This will not work with MFA"}

    $mergedObject = @()
    foreach ($tenant in $tenants) {
        $result = Get-TenantGraphAPIData -DelegatedAdminCred $DelegatedAdminCred -Tenant $Tenant -GraphAPIURI $URI -TenantId $tenantID -RefreshToken $refreshToken
        $mergedObject += $result
    }
    return $mergedObject
}