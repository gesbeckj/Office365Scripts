Function Get-ATPSummary {
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$TenantsList
    )

    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $here = $PSScriptRoot
    }
    . "$here\..\Get-AllTenantUserLicenses\Get-AllTenantUserLicenses.ps1"

    $ALlusers = Get-AllTenantUserLicenses
    $Tenants = $AllUsers.Tenant | Sort-Object -Unique
    $Summary = @()
    foreach ($tenant in $tenants) {
        $LicensedUsers = $AllUsers | Where-Object {$_.Tenant -eq $tenant} | Where-Object {$_.License.length -gt 2} 
        $ATPUsers = $LicensedUsers | Where-Object {$_.License -like "*Advanced Threat*"}
        if ($LicensedUsers.GetType().Name -eq "PSCustomObject") {
            $LicensedUserCount = 1
        } else {
            $LicensedUserCount = $LicensedUsers.count
        }
        $ATPUserCount = $ATPUsers.count
        if ($null -eq $ATPUsers) {
            $ATPUserCount = 0
        } elseif ($ATPUsers.GetType().Name -eq "PSCustomObject") {
            $ATPUserCount = 1
        } else {
            $ATPUserCount = $ATPUsers.count
        }
        $TenantID = Get-MsolPartnerContract -DomainName $Tenant| Select-Object TenantId
        $ATPLicensesOwned = (get-msolaccountsku -TenantID $tenantID.tenantID | Where-Object {$_.SkuPartNumber -eq "ATP_ENTERPRISE"}).ActiveUnits
        $data = New-Object PSObject -Property @{
            Tenant           = $Tenant
            LicensedUsers    = $LicensedUserCount
            ATPUsers         = $ATPUserCount
            ATPLicensesOwned = $ATPLicensesOwned
        }
        $Summary += $data
    }
    return $summary
}