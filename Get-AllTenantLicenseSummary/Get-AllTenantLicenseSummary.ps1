Function Get-AllTenantLicenseSummary
{
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$TenantsList
    )
    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    else {
        $here = $PSScriptRoot
    }
    . "$here\..\Common\Connect-Office365.ps1"
    . "$here\..\Common\Get-LicenseName.ps1"
    if ($Null -eq $TenantsList) {
        $session = Connect-Office365 -ConnectMSOLOnly
        $session | out-null
        $tenants = Get-MsolPartnerContract
    }
    else {
        $session = Connect-Office365 -ConnectMSOLOnly
        $session | out-null
        $tenants = $TenantsList
    }
    $mergedObject = @()

    foreach  ($tenant in $tenants) {
        $Licenses = Get-MsolAccountSku -TenantId $tenant.TenantID 
        foreach ($license in $Licenses)
        {
            $licenseName = Get-LicenseName -licenseParts $license.skupartnumber
            $subscriptions = $license.SubscriptionIds
            foreach ($subscription in $subscriptions)
            {
                $subscriptionInfo = Get-MsolSubscription -TenantId $tenant.TenantId -SubscriptionId $subscription
                if ($subscriptionInfo.Status -eq 'Enabled')
                {
                if ($null -eq  $subscriptionInfo.OwnerObjectID)
                {
                    $isCSP = "False"
                }
                else
                {
                    $isCSP = "True"
                }
                $data = New-Object PSObject -Property @{
                    Tenant = $Tenant.Name
                    License = $Licensename
                    isCSP = $isCSP
                    Owned_Licenses = $subscriptionInfo.TotalLicenses
                    InUse_Licenses = $license.ConsumedUnits
                    UnusuedLicenses = ($license.ActiveUnits - $license.ConsumedUnits)
                    Date = [System.DateTime]::Today
                }
                $mergedObject += $data
            }
            }
        }
    }
    return $mergedObject

}