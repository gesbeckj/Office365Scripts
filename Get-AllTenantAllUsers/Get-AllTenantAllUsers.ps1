Function Get-AllTenantAllUsers {
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$TenantsList,
        [pscredential]$Credential,
        [string]$refreshToken,
        [string]$tenantID
    )

    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $here = $PSScriptRoot
    }
    . "$here\..\Common\Connect-Office365.ps1"
    . "$here\..\Get-TenantALLUsers\Get-TenantALLUsers.ps1"
    . "$here\..\Common\Get-LicenseName.ps1"
    if ($Null -eq $TenantsList) {
        $session = Connect-Office365 -ConnectMSOLOnly -Credential $credential -refreshToken $RefreshToken -tenantID $TenantID
        $session | out-null
        $tenants = Get-MsolPartnerContract
    } Else {
        $session = Connect-Office365 -ConnectMSOLOnly -Credential $credential -refreshToken $RefreshToken -tenantID $TenantID
        $session | out-null
        $tenants = $TenantsList
    }
    $mergedObject = @()

    
    foreach ($tenant in $tenants) {
        $mergedObject += Get-TenantALLUsers -TenantDomainName $tenant.DefaultDomainName 
    }
    $FullResults = @()
    foreach ($object in $mergedObject)
    {
        $MFAStatus = ""
        if ($null -ne $object.StrongAuthenticationRequirements.State ) 
        {
            $MFAStatus = $object.StrongAuthenticationRequirements.State
        }
        else {
            
                $MFAStatus = 'Disabled'
            
        }
        $object | add-member MFAStatus $MFAStatus
        $licenseParts = ($Object.licenses.AccountSku.SkuPartNumber)
        $userLicense = Get-LicenseName -LicenseParts $licenseParts
        $object | add-member userLicense $userLicense
        $fullresults += $object
    }
    return $fullresults
}