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
    . "$here\..\Common\Get-LicenseName.ps1"
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
    $FullResults = @()
    foreach ($object in $mergedObject)
    {
        $MFAStatus = ""
        if ( $object.StrongAuthenticationRequirements.State -ne $null) 
        {
            $MFAStatus = $object.StrongAuthenticationRequirements.State
        }
        else {
            
                $MFAStatus = 'DISABLED'
            
        }
        $object | add-member MFAStatus $MFAStatus
        $licenseParts = ($Object.licenses.AccountSku.SkuPartNumber)
        $userLicense = Get-LicenseName -LicenseParts $licenseParts
        $object | add-member userLicense $userLicense
        $fullresults += $object
    }
    return $fullresults
}