$Base = "https://graph.microsoft.com/beta/reports/getMailboxUsageDetail(period='D7')?"
$JSON = '$format=application/json'
$URI = $base + $JSON

$MailboxInfo = Get-AllTenantGraphAPIData -TenantsList $tenants -DelegatedAdminCred $cred -URI $uri



$Base = "https://graph.microsoft.com/beta/reports/getOneDriveUsageAccountDetail(period='D30')?"
$JSON = '$format=application/json'
$URI = $base + $JSON
$OneDriveInfo = Get-AllTenantGraphAPIData -TenantsList $tenants -DelegatedAdminCred $cred -URI $uri




$Base = "https://graph.microsoft.com/beta/reports/getEmailActivityUserDetail(period='D7')?"
$JSON = '$format=application/json'
$URI = $base + $JSON
$Mailflow = Get-AllTenantGraphAPIData -TenantsList $tenants -DelegatedAdminCred $cred -URI $uri