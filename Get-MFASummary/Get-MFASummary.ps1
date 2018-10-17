Function Get-MFASummary
{
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$TenantsList
    )

    $Allusers = Get-AllTenantMFAUsers
    $Tenants = $AllUsers.Tenant | Sort-Object -Unique
    $Summary = @()
    foreach ($tenant in $tenants)
    {
        $LicensedUsers = $AllUsers | Where-Object {$_.Tenant -eq $tenant} #| Where-Object {$_.License.length -gt 2} 
        Write-Output $LicensedUsers.count
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
        $data = New-Object PSObject -Property @{
            Tenant = $Tenant
            LicensedUsers = $LicensedUserCount
            MFAUsers = $MFAUsersCount
        }
        $Summary += $data
}
