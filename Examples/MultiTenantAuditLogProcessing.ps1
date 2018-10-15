$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\Common\Connect-Office365.ps1"
. "$here\..\Get-TenantSuccessfulLogins\Get-TenantSuccessfulLogins.ps1"
$session = Connect-Office365 -ConnectMSOLOnly
$session | out-null
$tenants = Get-MsolPartnerContract
$DelegatedAdminCred = Get-Credential -Message "Enter delegated administrative credentials. This will not work with MFA"
$mergedObject = @()

foreach ($tenant in $tenants)
{
    $mergedObject += Get-TenantSuccessfulLogins -TenantDomainName $tenant.DefaultDomainName -DelegatedAdminCred $DelegatedAdminCred
}
