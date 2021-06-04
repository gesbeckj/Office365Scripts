Disable-AzureRmContextAutosave -Scope Process
$ServicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $ServicePrincipalConnection.TenantId `
    -ApplicationId $ServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint
$AzureContext = Select-AzureRmSubscription -SubscriptionId $ServicePrincipalConnection.SubscriptionID
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
$SQLQuery = "IF NOT EXISTS (SELECT * 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME = 'MobileDeviceMailboxPolicy')
CREATE TABLE [dbo].[MobileDeviceMailboxPolicy](
[AdminDisplayName] varchar(MAX),
[AllowApplePushNotifications] bit,
[AllowBluetooth] varchar(MAX),
[AllowBrowser] bit,
[AllowCamera] bit,
[AllowConsumerEmail] bit,
[AllowDesktopSync] bit,
[AllowExternalDeviceManagement] bit,
[AllowGooglePushNotifications] bit,
[AllowHTMLEmail] bit,
[AllowInternetSharing] bit,
[AllowIrDA] bit,
[AllowMicrosoftPushNotifications] bit,
[AllowMobileOTAUpdate] bit,
[AllowNonProvisionableDevices] bit,
[AllowPOPIMAPEmail] bit,
[AllowRemoteDesktop] bit,
[AllowSimplePassword] bit,
[AllowSMIMEEncryptionAlgorithmNegotiation] varchar(MAX),
[AllowSMIMESoftCerts] bit,
[AllowStorageCard] bit,
[AllowTextMessaging] bit,
[AllowUnsignedApplications] bit,
[AllowUnsignedInstallationPackages] bit,
[AllowWiFi] bit,
[AlphanumericPasswordRequired] bit,
[ApprovedApplicationList] bit,
[AttachmentsEnabled] bit,
[DeviceEncryptionEnabled] bit,
[DevicePolicyRefreshInterval] varchar(MAX),
[DistinguishedName] varchar(MAX),
[ExchangeObjectId] varchar(100),
[ExchangeVersion] varchar(MAX),
[Guid] varchar(100),
[Id] varchar(MAX),
[Identity] varchar(MAX),
[IrmEnabled] bit,
[IsDefault] bit,
[IsValid] bit,
[MaxAttachmentSize] varchar(MAX),
[MaxCalendarAgeFilter] varchar(MAX),
[MaxEmailAgeFilter] varchar(MAX),
[MaxEmailBodyTruncationSize] varchar(MAX),
[MaxEmailHTMLBodyTruncationSize] varchar(MAX),
[MaxInactivityTimeLock] varchar(MAX),
[MaxPasswordFailedAttempts] varchar(MAX),
[MinPasswordComplexCharacters] int,
[MinPasswordLength] int,
[MobileOTAUpdateMode] varchar(MAX),
[Name] varchar(MAX),
[ObjectCategory] varchar(MAX),
[ObjectClass] varchar(MAX),
[ObjectState] varchar(MAX),
[OrganizationId] varchar(MAX),
[OriginatingServer] varchar(MAX),
[PasswordEnabled] bit,
[PasswordExpiration] varchar(MAX),
[PasswordHistory] int,
[PasswordRecoveryEnabled] bit,
[RequireDeviceEncryption] bit,
[RequireEncryptedSMIMEMessages] bit,
[RequireEncryptionSMIMEAlgorithm] varchar(MAX),
[RequireManualSyncWhenRoaming] bit,
[RequireSignedSMIMEAlgorithm] varchar(MAX),
[RequireSignedSMIMEMessages] bit,
[RequireStorageCardEncryption] bit,
[UnapprovedInROMApplicationList] varchar(MAX),
[UNCAccessEnabled] bit,
[WhenChanged] datetime,
[WhenChangedUTC] datetime,
[WhenCreated] datetime,
[WhenCreatedUTC] datetime,
[WSSAccessEnabled] bit,
[Tenant] varchar(100),[Date] datetime)"
$params.query = $SQLQuery
$Result = Invoke-SQLCmd @params

foreach ($tenant in $tenants) {
    $params = @{"TenantDomainName"=$tenant.DefaultDomainName;"TenantName"=$tenant.name}
    Start-Sleep -seconds 10

$job = Start-AzureRmAutomationRunbook -Name Get-TenantMobileDeviceMailboxPolicy -AutomationAccountName "AzureAutomation" -ResourceGroupName "PowerBI" -Parameters $params}
