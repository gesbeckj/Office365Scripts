Function Get-MFASummary{
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
    . "$here\..\Get-AllTenantMFAUsers\Get-AllTenantMFAUsers.ps1"
    $Allusers = Get-AllTenantMFAUsers -credential $credential
    $Tenants = $AllUsers.Tenant | Sort-Object -Unique
    $Summary = @()
    foreach ($tenant in $tenants)
    {
        $LicensedUsers = $AllUsers | Where-Object {$_.Tenant -eq $tenant} #| Where-Object {$_.License.length -gt 2} 
        Write-Verbose $LicensedUsers.count
        $MFAUsers = $LicensedUsers | Where-Object {$_.MFAStatus -ne "Disabled"}
        if ($LicensedUsers.GetType().Name -eq "PSCustomObject")
        {
            $LicensedUserCount = 1
        }
        else
        {
            $LicensedUserCount  = $LicensedUsers.count
        }
        $MFAUsersCount = $MFAUsers.count
        if ($null -eq $MFAUsers)
        {
            $MFAUsersCount = 0
        }
        elseif ($MFAUsers.GetType().Name -eq "PSCustomObject")
        {
            $MFAUsersCount = 1
        }
        else
        {
            $MFAUsersCount  = $MFAUsers.count
        }
        $company = Get-MsolPartnerContract -DomainName $tenant
        $data = New-Object PSObject -Property @{
            Tenant = $company.Name
            LicensedUsers = $LicensedUserCount
            MFAUsers = $MFAUsersCount
            Date = [System.DateTime]::Today
        }
        $Summary += $data
}
return $Summary
}
