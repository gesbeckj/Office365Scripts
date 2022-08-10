$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$KeyVault = Get-AzureRmKeyVault -VaultName "AberdeanCSP-Vault"
$databaseName = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PowerBIDatabasename'
$sqlServerFQDN = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PowerBISQLServer'
$sqlAdministratorLogin = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PowerBISQLLogin'
$sqlAdministratorLoginPassword = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PowerBISQLPassword'
$Office365Login = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'AutomationAppID'
$Office365LoginPassword = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'AutomationAppSecret'
$RefreshToken = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'AutomationRefreshToken'
$TenantID = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PartnerDomainName'

$secpassword = ConvertTo-SecureString $Office365LoginPassword.SecretValueText -AsPlainText -Force
$Office365Creds = New-Object System.Management.Automation.PSCredential($Office365Login.SecretValueText,$secpassword)

$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Common/Connect-Office365.ps1'
$TempFile = $Env:Temp + '\Common\Connect-Office365.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile
. $TempFile
$session = Connect-Office365 -ConnectMSOLOnly -credential $Office365Creds -refreshtoken $RefreshToken.SecretValueText -TenantId $TenantID.SecretValueText
$session | out-null
$tenants = Get-MsolPartnerContract
$params = @{
    'Database' = $databaseName.SecretValueText
    'ServerInstance' = $sqlServerFQDN.SecretValueText
    'Username' = $sqlAdministratorLogin.SecretValueText
    'Password' = $sqlAdministratorLoginPassword.SecretValueText
    'OutputSqlErrors' = $true
    'Query' = 'SELECT GETDate()'
}
#Check for Table, create if it not exist
$SQLQuery = "IF NOT EXISTS (SELECT * 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME = 'AllTenantCompanyInformation')
CREATE TABLE [dbo].[AllTenantCompanyInformation](
[AllowAdHocSubscriptions] varchar(MAX),
[AllowEmailVerifiedUsers] varchar(MAX),
[AuthorizedServiceInstances] varchar(MAX),
[AuthorizedServices] varchar(MAX),
[City] varchar(MAX),
[CompanyDeletionStartTime] datetime,
[CompanyTags] varchar(MAX),
[CompanyType] varchar(MAX),
[CompassEnabled] varchar(MAX),
[Country] varchar(MAX),
[CountryLetterCode] varchar(MAX),
[DapEnabled] varchar(MAX),
[DefaultUsageLocation] varchar(MAX),
[DirectorySynchronizationEnabled] varchar(MAX),
[DirectorySynchronizationStatus] varchar(MAX),
[DirSyncApplicationType] varchar(MAX),
[DirSyncClientMachineName] varchar(MAX),
[DirSyncClientVersion] varchar(MAX),
[DirSyncServiceAccount] varchar(MAX),
[DisplayName] varchar(MAX),
[ExtensionData] varchar(MAX),
[InitialDomain] varchar(MAX),
[LastDirSyncTime] datetime,
[LastPasswordSyncTime] datetime,
[MarketingNotificationEmails] varchar(MAX),
[MultipleDataLocationsForServicesEnabled] varchar(MAX),
[ObjectId] varchar(100),
[PasswordSynchronizationEnabled] varchar(MAX),
[PortalSettings] varchar(MAX),
[PostalCode] varchar(MAX),
[PreferredLanguage] varchar(MAX),
[ReleaseTrack] varchar(MAX),
[ReplicationScope] varchar(MAX),
[RmsViralSignUpEnabled] varchar(MAX),
[SecurityComplianceNotificationEmails] varchar(MAX),
[SecurityComplianceNotificationPhones] varchar(MAX),
[SelfServePasswordResetEnabled] varchar(MAX),
[ServiceInformation] varchar(MAX),
[ServiceInstanceInformation] varchar(MAX),
[State] varchar(MAX),
[Street] varchar(MAX),
[SubscriptionProvisioningLimited] varchar(MAX),
[TechnicalNotificationEmails] varchar(MAX),
[TelephoneNumber] varchar(MAX),
[UIExtensibilityUris] varchar(MAX),
[UsersPermissionToCreateGroupsEnabled] varchar(MAX),
[UsersPermissionToCreateLOBAppsEnabled] varchar(MAX),
[UsersPermissionToReadOtherUsersEnabled] varchar(MAX),
[UsersPermissionToUserConsentToAppEnabled] varchar(MAX),
[Tenant] varchar(100),[Date] datetime)"
$params.query = $SQLQuery
$Result = Invoke-SQLCmd @params

foreach ($tenant in $tenants) {

$record = Get-MsolCompanyInformation -TenantId $tenant.TenantId

$replace = "'"
$new = "''"
foreach($record in $records)
{
$TenantName = $TenantName.replace($replace, $new)
$Date = [System.DateTime]::Today
$params.Query = "
INSERT INTO [dbo].[AllTenantCompanyInformation] (
[AllowAdHocSubscriptions],
[AllowEmailVerifiedUsers],
[AuthorizedServiceInstances],
[AuthorizedServices],
[City],
[CompanyDeletionStartTime],
[CompanyTags],
[CompanyType],
[CompassEnabled],
[Country],
[CountryLetterCode],
[DapEnabled],
[DefaultUsageLocation],
[DirectorySynchronizationEnabled],
[DirectorySynchronizationStatus],
[DirSyncApplicationType],
[DirSyncClientMachineName],
[DirSyncClientVersion],
[DirSyncServiceAccount],
[DisplayName],
[ExtensionData],
[InitialDomain],
[LastDirSyncTime],
[LastPasswordSyncTime],
[MarketingNotificationEmails],
[MultipleDataLocationsForServicesEnabled],
[ObjectId],
[PasswordSynchronizationEnabled],
[PortalSettings],
[PostalCode],
[PreferredLanguage],
[ReleaseTrack],
[ReplicationScope],
[RmsViralSignUpEnabled],
[SecurityComplianceNotificationEmails],
[SecurityComplianceNotificationPhones],
[SelfServePasswordResetEnabled],
[ServiceInformation],
[ServiceInstanceInformation],
[State],
[Street],
[SubscriptionProvisioningLimited],
[TechnicalNotificationEmails],
[TelephoneNumber],
[UIExtensibilityUris],
[UsersPermissionToCreateGroupsEnabled],
[UsersPermissionToCreateLOBAppsEnabled],
[UsersPermissionToReadOtherUsersEnabled],
[UsersPermissionToUserConsentToAppEnabled],
[Tenant],[Date])
VALUES (
'$($Record.AllowAdHocSubscriptions)',
'$($Record.AllowEmailVerifiedUsers)',
'$($Record.AuthorizedServiceInstances)',
'$($Record.AuthorizedServices)',
'$($Record.City)',
'$($Record.CompanyDeletionStartTime)',
'$($Record.CompanyTags)',
'$($Record.CompanyType)',
'$($Record.CompassEnabled)',
'$($Record.Country)',
'$($Record.CountryLetterCode)',
'$($Record.DapEnabled)',
'$($Record.DefaultUsageLocation)',
'$($Record.DirectorySynchronizationEnabled)',
'$($Record.DirectorySynchronizationStatus)',
'$($Record.DirSyncApplicationType)',
'$($Record.DirSyncClientMachineName)',
'$($Record.DirSyncClientVersion)',
'$($Record.DirSyncServiceAccount)',
'$($Record.DisplayName)',
'$($Record.ExtensionData)',
'$($Record.InitialDomain)',
'$($Record.LastDirSyncTime)',
'$($Record.LastPasswordSyncTime)',
'$($Record.MarketingNotificationEmails)',
'$($Record.MultipleDataLocationsForServicesEnabled)',
'$($Record.ObjectId)',
'$($Record.PasswordSynchronizationEnabled)',
'$($Record.PortalSettings)',
'$($Record.PostalCode)',
'$($Record.PreferredLanguage)',
'$($Record.ReleaseTrack)',
'$($Record.ReplicationScope)',
'$($Record.RmsViralSignUpEnabled)',
'$($Record.SecurityComplianceNotificationEmails)',
'$($Record.SecurityComplianceNotificationPhones)',
'$($Record.SelfServePasswordResetEnabled)',
'$($Record.ServiceInformation)',
'$($Record.ServiceInstanceInformation)',
'$($Record.State)',
'$($Record.Street)',
'$($Record.SubscriptionProvisioningLimited)',
'$($Record.TechnicalNotificationEmails)',
'$($Record.TelephoneNumber)',
'$($Record.UIExtensibilityUris)',
'$($Record.UsersPermissionToCreateGroupsEnabled)',
'$($Record.UsersPermissionToCreateLOBAppsEnabled)',
'$($Record.UsersPermissionToReadOtherUsersEnabled)',
'$($Record.UsersPermissionToUserConsentToAppEnabled)',
'$TenantName','$Date');
GO"
$Result = Invoke-SQLCmd @params
}
}