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



$mergedObject = @()
For ($i=2; $i -le 30; $i++)
{
    $tempDate = $date.AddDays(-$i)
    $dateString = $tempdate.year.toString() + '-'  + $tempdate.month.tostring() + '-' + $tempdate.day.tostring()
    $Base = "https://graph.microsoft.com/beta/reports/getTeamsUserActivityUserDetail(date=$datestring)?" 
    $JSON = '$format=application/json'
    $URI = $base + $JSON
    $MailbyDate = Get-AllTenantGraphAPIData -TenantsList $tenants -DelegatedAdminCred $cred -URI $uri
    $mergedObject += $MailbyDate
}
$mergedObject | export-csv c:\temp\TeamsUsage.csv -NoTypeInformation