$Cred = Get-Credential
Connect-AzureAD -Credential $cred
$Tenants = Get-AzureADContract -All $true

$Base = 'https://graph.microsoft.com/beta/security/secureScores?$top=1'
$JSON = ''
$URI = $base + $JSON
$SecureScore = Get-AllTenantGraphAPIData -TenantsList $tenants -DelegatedAdminCred $cred -URI $uri -verbose

$base = 'https://graph.microsoft.com/beta/security/secureScoreControlProfiles'
$JSON = ''
$URI = $base + $JSON
$SecureScoreControlInfo = Get-AllTenantGraphAPIData -TenantsList $tenants -DelegatedAdminCred $cred -URI $uri -verbose




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

$cred = Get-Credential
$tempDate = Get-Date -date (Get-Date).AddDays(-1) -format "MM dd yyyy"
$dateString = $tempdate.Substring(6,4)+ '-'  + $tempdate.Substring(0,2) + '-' + $tempdate.Substring(3,2)
$JSON = '$format=application/json'
$URI = $base + $JSON

$MailUsage = @()
$Base = "https://graph.microsoft.com/beta/reports/getEmailActivityUserDetail(date=$datestring)?" 
$URI = $base + $JSON
$MailUsage = Get-AllTenantGraphAPIData -TenantsList $tenants -DelegatedAdminCred $cred -URI $uri
$MailUsage | Export-Csv -path c:\temp\MailUsage1.csv -NoTypeInformation

$Base = "https://graph.microsoft.com/beta/reports/getEmailAppUsageUserDetail(date=$datestring)?" 
$URI = $base + $JSON
$MailAppUsage = Get-AllTenantGraphAPIData -TenantsList $tenants -DelegatedAdminCred $cred -URI $uri
$MailAppUsage | Export-Csv c:\temp\MailAppUsage.csv -NoTypeInformation

$Base = "https://graph.microsoft.com/beta/reports/getOffice365ActivationsUserDetail?" 
$URI = $base + $JSON
$OfficeInstalls = Get-AllTenantGraphAPIData -TenantsList $tenants -DelegatedAdminCred $cred -URI $uri
$OfficeInstalls | Export-Csv c:\temp\OfficeInstalls.csv -NoTypeInformation

$Base = "https://graph.microsoft.com/beta/reports/getOneDriveActivityUserDetail(date=$datestring)?" 
$URI = $base + $JSON
$OneDriveActivity = Get-AllTenantGraphAPIData -TenantsList $tenants -DelegatedAdminCred $cred -URI $uri
$OneDriveActivity | Export-Csv c:\temp\OneDriveActivity.csv -NoTypeInformation

$Base = "https://graph.microsoft.com/beta/reports/getOneDriveUsageAccountDetail(date=$datestring)?" 
$URI = $base + $JSON
$OneDriveUsage = Get-AllTenantGraphAPIData -TenantsList $tenants -DelegatedAdminCred $cred -URI $uri
$OneDriveUsage | Export-Csv c:\temp\OneDriveUsagee.csv -NoTypeInformation

$All = @()
foreach ($item in $OneDriveUsage)
{
    $single = New-Object PSObject -Property @{
        Displayname = $item.ownerDisplayName
        TotalSize = $item.storageAllocatedInBytes
        UsedSize = $item.storageUsedInBytes
        FileCount = $item.fileCount
        Date = $item.reportRefreshDate
        LastActivity = $item.lastActivityDate
        ActiveFileCount = $item.activeFileCount
        Tenant = $TenantName
    }
$all += $single
}
$test = $OneDriveUsage | Where {$_.TenantName -ne $null}

$Base = "https://graph.microsoft.com/beta/reports/getSharePointActivityUserDetail(date=$datestring)?" 
$URI = $base + $JSON
$SharePointActivit = Get-AllTenantGraphAPIData -TenantsList $tenants -DelegatedAdminCred $cred -URI $uri
$SharePointActivit | Export-Csv c:\temp\SharePointActivit.csv -NoTypeInformation

$Base = "https://graph.microsoft.com/beta/reports/getSkypeForBusinessActivityUserDetail(date=$datestring)?" 
$URI = $base + $JSON
$SkypeForBusinessActivity= Get-AllTenantGraphAPIData -TenantsList $tenants -DelegatedAdminCred $cred -URI $uri
$SkypeForBusinessActivity | Export-Csv c:\temp\SkypeForBusinessActivity.csv -NoTypeInformation

$merged = @()
foreach ($item in $data)
{
    $single = New-Object PSObject -Property @{
        displayName = $item.displayName
        EmailAddress = $item.userPrincipalName
        SendCount = $item.sendCount
        RecievedCount = $item.receiveCount
        ReadCount = $item.readCount
        Tenant    = $item.TenantName
        Date = $item.reportRefreshDate
    }
$merged += $single
}

$uri1 = 'https://graph.microsoft.com/beta/reports/getOneDriveUsageAccountDetail(period=''D7'')?$format=application/json'

$Results = Get-TenantGraphAPIData -Tenant $SW -DelegatedAdminCred $cred -GraphAPIURI $URI1

#ALLTENANT USERS
$users = Get-AllTenantAllUsers
$users = Get-AllTenantAllUsers -Credential $cred
$users | where {$_.usertype -neq "guest" -and $_.isLicensed -eq $true}

$licenseParts = ((Get-MsolUser -UserPrincipalName $mailbox.userprincipalname -TenantId $TenantID -ErrorAction ignore).licenses.AccountSku.SkuPartNumber)
        $userLicense = Get-LicenseName -LicenseParts $licenseParts


        CREATE TABLE [dbo].[UserDetails] (
[TenantName] varchar(100),
[MFAStatus] varchar(20),
[userLicense] varchar(250),
[DisplayName] varchar(100),
[FirstName] varchar(50),
[LastName] varchar(100),
[LastPasswordChangeTimestamp] datetime,
[PasswordNeverExpires] bit,
[UserPrincipalName] varchar(100),
[WhenCreated] datetime,
[date] datetime
)